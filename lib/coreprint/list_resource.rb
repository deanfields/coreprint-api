module CorePrint
  class ListResource
    def initialize(account)
      @account = account
      @cached = nil
    end

    def fetch(params = {})
      @cached = ApiResource.ensure_array(@account.request(:get, list_service, params))
    end

    def query(id)
      @cached.each do |c|
        return c if c[:id] == id
      end
    end

    # Override
    def all
    end

    def find(id)
    end

    def create(params = {})
    end

    protected

    def list_service
      ""
    end
  end
end
