
module CorePrint
  class Products < ListResource
    def all
      # Load all products in the catalogue
      products = []

      @account.catalogues.each do |catalogue|
        data = fetch(catalogueid: catalogue)

        # If there are no products in the root of the catalogue
        data = [] if !data[0]

        @account.categories.each do |c|
          fetched = fetch(categoryid: c[:id])
          data.concat(fetched) if fetched.is_a?(Array)
        end

        data.each do |p|
          products << Product.new(@account, p)
        end
      end

      return products
    end

    def category(id)
      products = []
      fetched = fetch(categoryid: id)
      fetched.each do |p|
        products << Product.new(@account, p)
      end

      return products
    end

    def find(id)
      Product.new(@account, { id: id })
    end

    def search(query)
      fetch(search: query)
    end

    protected

    def list_service
      "findproducts"
    end
  end

  class Product < ApiResource
    attr_accessor :json, :name, :code, :description, :printoption, :preview, :thumbnail, :uom, :userupload, :templated, :stock, :outofstock, :favourite, :created, :modified, :availableqtys, :minqty, :maxqty, :defaultprice

    def load
      begin
        self.json = @account.request(:get, product_reload_service, { :productid => self.id })
        set_attributes(self.json)
        return self
      rescue
        return nil
      end
    end

    def prices
      ApiResource.ensure_array @account.request(:get, product_prices_service, { :productid => self.id })
    end

    def properties
      data = ApiResource.ensure_array @account.request(:get, product_properties_service, { :productid => self.id })
      parsed = []

      data[0].each do |page, components|
        if page.is_a?(String) && page.include?("page")
          pageno = page[5..-1]

          components.each do |key, comp|
            if key.is_a?(String) && key.include?("component")
              component = {
                name: comp["name"],
                label: comp["label"],
                input_type: comp["inputtype"],
                content_type: comp["contenttype"],
                content_id: comp["contentid"],
                order: comp["childorder"],
                icid: comp["icid"],
                required: comp["required"],
                page: pageno.to_i
              }

              if component[:content_type] == "LIST"
                component[:options] = {}
                self.list_entries(component[:content_id]).each do |opt|
                  component[:options][opt[:label]] = opt[:value]
                end
              elsif component[:content_type] == "ADDRESS"
                component[:options] = {}
                self.addresses(component[:content_id]).each do |opt|
                  component[:options][opt[:label]] = opt[:value]
                end
              end

              parsed << component
            end
          end
        end
      end

      return parsed
    end

    def list_entries(id)
      ApiResource.ensure_array @account.request(:get, product_editor_lists_service, { :contentid => id })
    end

    def addresses(id)
      ApiResource.ensure_array @account.request(:get, product_editor_addresses_service, { :contentid => id })
    end

    def proof(customizations, overrides = {})
      template = @account.request(:get, product_proof_format_service, { :productid => self.id })

      options = {
        page: 1,
        format: "image",
        width: 400
      }
      options.merge!(overrides)

      template["page"] = options[:page]
      template["mimetype"] = options[:format]
      template["width"] = options[:width]

      template["content"].each do |label, value|
        template["content"][label] = ""
      end

      template["content"].each do |label, value|
        template["content"][label] = customizations[label.to_sym] if customizations.has_key?(label.to_sym)
      end

      @account.request(:post, product_proof_service, { :productid => self.id }, template)
    end

    def print_ready_pdf(customizations)
      # Setup a basket
      @account.basket.sync([
        { :product => self.id, :quantity => 1, :customizations => customizations }
      ])

      # Create an order
      order = @account.orders.create(:email => "support@realripple.com", :deliveryname => "Print Ready PDF", invoicetelephone: "07777 777777")

      order_line = order.lines[0]

      # Generate a 'proof' using the order line id
      template = {
        "orderlineid" => order_line[:id],
        "proofstamp" => false
      }
      @account.request(:post, product_proof_service, { :productid => self.id }, template)
    end

    private

    def product_reload_service
      "getproduct"
    end

    def product_prices_service
      "getproductpricelist"
    end

    def product_properties_service
      "geteditor"
    end

    def product_editor_lists_service
      "geteditorlistentries"
    end

    def product_editor_addresses_service
      "geteditoraddresses"
    end

    def product_proof_service
      "getproof"
    end

    def product_proof_format_service
      "geteditorproofformat"
    end
  end
end
