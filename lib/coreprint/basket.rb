module CorePrint
  class Basket
    def initialize(account)
      @account = account
      @items = []
    end

    def list
      response = @account.request(:post, basket_list_service)

      if response.empty?
        return []
      else
        return ApiResource.ensure_array response
      end
    end

    def items
      # Returns :items => [], :delivery => {}, :total => {}
      response = @account.request(:post, basket_list_service, { :productinfo => true })

      unless response.is_a? Array
        return []
      else
        CorePrint.log response

        # 1 item will always be delivery and 1 will be total
        items = response.count - 2
        return {
          :items => response.slice(0, items), # Count from 0
          :delivery => response[response.count - 2],
          :total => response[response.count - 1]
        }
      end
    end

    def proof(id, type = 'pdf')
      @account.request(:post, basket_proof_service, {}, { "basketentryid" => id, "mimetype" => type })
    end

    def count
      response = @account.request(:get, basket_count_service)
      if response.has_key?("number")
        return response["number"]
      else
        return 0
      end
    end

    def empty?
      return self.count == 0
    end

    def add(item)
      @account.request(:put, basket_add_service, {}, { "0" => {
        productid: item[:id],
        quantity: item[:quantity],
        documentsnapshot: item[:customizations]
      }})
    end

    def transfer(item)
      @account.request(:post, basket_transfer_service, {}, { "0" => {
        id: item[:id]
      }})
    end

    def add_dam(item)
      @account.request(:put, basket_add_service, {}, { "0" => {
        productid: item[:id],
        quantity: item[:quantity],
        damitem: item[:damitem]
      }})
    end

    def remove(item)
      @account.request(:post, basket_remove_service, {}, { "0" => { "id" => item }})
    end

    def clear
      return if self.empty?

      request = {}
      contents = self.list

      0.upto(self.count - 1) do |i|
        request[i.to_s] = { "id" => contents[i][:id] }
        i += 1
      end

      @account.request(:post, basket_remove_service, {}, request)
    end

    # @basket.sync([
    #   { :product => 7824, :quantity => 3, :customizations => { :name => "Joe Bloggs", :website => "example.com" }},
    #   { :product => 7825, :quantity => 50, :customizations => { :name => "Gill Bloggs", :website => "example.org" }}
    # ])
    def sync(basket)
      self.clear

      basket.each do |item|
        self.add(item)
      end

      if self.count != basket.count
        raise "Could not synchronize basket: expected #{basket.count} got #{self.count} items"
      end
    end

    private

    def basket_count_service
      "getbasketsize"
    end

    def basket_list_service
      "getbasket"
    end

    def basket_proof_service
      "getbasketproof"
    end

    def basket_remove_service
      "removebasketentry"
    end

    def basket_add_service
      "addbasketentry"
    end

    def basket_transfer_service
      "transferbasketentry"
    end
  end
end
