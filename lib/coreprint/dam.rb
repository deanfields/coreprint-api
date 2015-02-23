module CorePrint
  class Dam
    def initialize(account)
      @account = account
    end

    def save(fh)
      response = @account.request(:stream, dam_save_service, { }, fh)

      if response.has_key?(:action) && response[:action] == "ok"
        return response
      else
        return false
      end
    end

    def delete(item)
      response = @account.request(:post, dam_delete_service, {}, { :id => item })
      puts response

      if response.has_key?(:action) && response[:action] == "deleted"
        return true
      else
        return false
      end
    end

    private

    def dam_save_service
      "savedamitem"
    end

    def dam_delete_service
      "deletedamitem"
    end
  end
end
