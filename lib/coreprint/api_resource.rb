module CorePrint
  class ApiResource
    attr_accessor :id

    def initialize(account, params)
      @account = account

      set_attributes(params)
    end

    def set_attributes(params)
      params.each do |k,v|
        send("#{k}=",v) if self.respond_to? k
      end
    end

    def self.ensure_array(d)
      if d.is_a?(Hash)
        if d.length == 0
          return {}
        else
          return [d]
        end
      else
        return d
      end
    end

    def save
      if self.id.present?
        self.update
      else
        self.create
      end
    end

    def create
      @account.request(:put, create_service, {}, { "0" => self.coreprint_format })
    end

    def update
      @account.request(:put, update_service, {}, { "0" => self.coreprint_format })
    end

    def destroy
      @account.request(:put, update_service, {}, { "0" => self.coreprint_format.merge({ :remove => "true" }) })
    end

    protected

    def update_service
      ""
    end

    def create_service
      ""
    end

    def coreprint_format
      {}
    end
  end
end
