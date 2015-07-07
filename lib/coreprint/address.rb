module CorePrint
  class Addresses < ListResource
    def all
      fetch({ type: 2 })
    end

    def find(id)
      CorePrint::Address.new(@account, { id: id, type: 2 }).load
    end

    def create(params = {})
      address = CorePrint::Address.new(@account, params)
      request = address.save

      if request[:action] == "Added" ||  request[:action] == "Updated"
        request[:id]
      else
        return false
      end
    end

    protected

    def list_service
      "getaddresses"
    end
  end

  class Address < ApiResource
    attr_accessor :label, :type, :deliverto, :city, :address1, :address2, :state, :country, :postcode

    def streets=(hash)
      address1 = hash["0"]
      address2 = hash["1"]
    end

    def load
      begin
        raw = @account.request(:get, find_service, { :addressid => self.id })
        self.address1 = raw[:streets]["0"]
        self.address2 = raw[:streets]["1"]
        set_attributes(raw)
        return self
      rescue
        return nil
      end
    end

    protected

    def update_service
      "updateaddress"
    end

    def create_service
      "addaddress"
    end

    def find_service
      "getaddress"
    end

    def coreprint_format
      hash = {
        type: self.type,
        label: self.label,
        deliverto: self.deliverto,
        streets: { "0" => self.address1, "1" => self.address2 },
        city: self.city,
        state: self.state,
        postcode: self.postcode,
        country: self.country
      }
      hash[:streets]["1"] = "" if !hash[:streets]["1"].present?
      hash[:id] = self.id if self.id.present?
      hash.each { |k, v| hash[k] = "" if !v.present? }

      return hash
    end
  end
end
