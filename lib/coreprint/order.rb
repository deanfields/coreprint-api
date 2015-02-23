
module CorePrint
  class Orders < ListResource
    def all
      # Load all orders
      orders = []
      @cached = ApiResource.ensure_array(@account.request(:post, list_service, { :useronly => true }, { fromdate: 1.year.ago }))
      data = @cached

      return [] unless data

      data.each do |o|
        neworder = Order.new(@account, o)
        neworder.raw = o
        orders << neworder
      end

      return orders
    end

    def find(id)
      Order.new(@account, { id: id })
    end

    def create(params = {})
      order = CorePrint::Order.new(@account, params)
      request = order.save

      if request["action"] == "Created"
        order.id = request["orderid"]
        order.ordernumber = request["ordernumber"]
        return order
      else
        raise "Unknown error creating order"
      end
    end

    protected

    def list_service
      "getorderreport"
    end
  end

  class Order < ApiResource
    attr_accessor :comments, :purchaseorder1, :purchaseorder2, :ordernumber, :invoice, :delivery, :invoicename, :invoicetelephone, :deliverytelephone, :deliveryname, :email, :raw

    def send_pdf
      response = @account.request(:get, order_send_pdf_service, { orderid: self.id })

      if response["Action"] == "PDF Sent"
        return true
      else
        return false
      end
    end

    def send_xml
      response = @account.request(:get, order_send_xml_service, { orderid: self.id })

      if response["Action"] == "Xml Order Message Sent"
        return true
      else
        return false
      end
    end

    def lines
      ApiResource.ensure_array @account.request(:get, order_get_lines_service, { orderid: self.id })
    end

    def load
      lines
      return self
    end

    def data
      raw = @account.request(:get, order_get_invoice, { orderid: self.id })
      raw[:orderlines] = ApiResource.ensure_array(CorePrint.convert_array(raw[:orderlines]))

      return raw
    end

    # Override create because we don't need to { "0" => { ... } }
    def create
      @account.request(:put, create_service, {}, self.coreprint_format)
    end

    protected

    def create_service
      "createorder"
    end

    def coreprint_format
      hash = {
        :invoice => self.invoice,
        :delivery => self.delivery,
        :invoicetelephone => self.invoicetelephone,
        :invoicename => self.invoicename,
        :email => self.email
      }

      hash[:comments] = self.comments if self.comments.present?
      hash[:purchaseorder1] = self.purchaseorder1 if self.purchaseorder1.present?
      hash[:purchaseorder2] = self.purchaseorder2 if self.purchaseorder2.present?

      return hash
    end

    private

    def self.order_list_service
      "getorderreport"
    end

    def self.order_create_service
      "createorder"
    end

    def order_get_invoice
      "getorder"
    end

    def order_send_xml_service
      "sendxmlordermessage"
    end

    def order_send_pdf_service
      "sendpdftoprinter"
    end

    def order_get_lines_service
      "getorderlines"
    end
  end
end
