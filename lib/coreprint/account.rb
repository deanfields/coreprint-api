
module CorePrint
  class Account < ApiResource
    def initialize(credentials)
      @credentials = credentials
    end

    def credentials
      @credentials
    end

    def request(method, service, params = {}, payload = nil)
      CorePrint.request(method, service, self, params, payload)
    end

    def addresses
      @addresses ||= CorePrint::Addresses.new(self)
    end

    def orders
      @orders ||= CorePrint::Orders.new(self)
    end

    def products
      @products ||= CorePrint::Products.new(self)
    end

    def basket
      @basket ||= CorePrint::Basket.new(self)
    end

    def dam
      @dam = CorePrint::Dam.new(self)
    end

    def details
      self.request(:get, account_details_service)
    end

    def exists? (email = nil)
      if email
        # Check for the existence of the customer
        request = self.request(:get, account_user_exists, { username: email })
      else
        # Check yourself before you wreck yourself
        request = self.request(:get, account_user_exists, { username: @credentials[:username] })
      end

      request["result"] == true
    end

    def valid?
      info = self.details

      if info.is_a?(Hash) && info[:email] && info[:email].length > 3
        return true
      else
        return false
      end
    end

    def check_permissions?(product_ids)
      available = []
      self.products.all.each do |p|
        available << p.id if product_ids.include? p.id
      end

      return available
    end

    def create_user(user)
      self.request(:put, account_create_service, {}, {
        :name => user[:email],
        :email => user[:email],
        :fullname => user[:name],
        :password => user[:password]
      })
    end

    # Only used for root user
    # IMPORTANT: Included for compatability of legacy code, use catalogue*s* in future
    def catalogue
      self.request(:get, account_catalogue_service)[:id]
    end

    def catalogues
      q = self.request(:get, account_catalogue_service)
      if q.is_a? Array
        return q.map { |c| c[:id] }
      else
        if q && q.has_key?(:id)
          return [ q[:id] ]
        else
          return []
        end
      end
    end

    def category_catalogue_items
      cats = []
      self.catalogues.each do |ctl|
        q = ApiResource.ensure_array(self.request(:get, account_categories_service, { :catalogueid => ctl }))
        q = [] if q == {}

        q.each do |cat|
         
          cats << cat
        end
        
      end
      
      return cats
    end

    def categories
      cats = []
      self.catalogues.each do |ctl|
        q = ApiResource.ensure_array(self.request(:get, account_categories_service, { :catalogueid => ctl }))
        q = [] if q == {}

        q.each do |cat|
         
          iterate_categories(cat, cats)
        end
        
      end
      
      return cats
    end

    def iterate_categories(h, kits)
     t = Hash.new
      h.each do |k, v|
        
        if k["id"]
          t[:id] = v

        elsif k["name"]
          t[:name] = v

        elsif k["preview"]
          t[:preview] = v

        elsif k["parent"]


        elsif k["categories"]

          
          v.each do |a, c|

            c["parent"] = k["id"]

            iterate_categories(c, kits)
          end

        end
        kits << t
      end
    end

  def category(id)
    c = []
     q = ApiResource.ensure_array(self.request(:get, account_category_service, { :categoryid => id }))
      q = [] if q == {}
      q.each do |cat|
        iterate_categories(cat, c)
      end

    return c
  end

    def change_user_password(email, pass)
      self.request(:put, update_user_service, {}, {
        name: email,
        email: email,
        password: pass
      })
    end

    def self.customer(user)
      account = CorePrint::Account.new({
        :key => user.key,
        :username => user.email,
        :password => user.password,
        :root => false
      })

      if account.exists?
        return account
      else

      end
    end

    def proof(product, customizations, overrides)
      options = {
        page: 1,
        format: "image",
        width: 400
      }
      options.merge!(overrides)

      template = {}
      template["productid"] = product
      template["page"] = options[:page]
      template["mimetype"] = options[:format]
      template["width"] = options[:width]
      template["content"] = customizations

      self.request(:post, "getproof", { :productid => product }, template)
    end

     def price(product, qty)
      options = {
        page: 1,
        format: "image",
        width: 400
      }

      self.request(:get, "getproductprice", { :productid => product, :qty => qty })
    end

    private

    def account_create_service
      "adduser"
    end

    def account_catalogue_service
      "findcatalogues"
    end

    def account_categories_service
      "findallcategories"
    end

    def account_category_service
      "findcategory"
    end

    def account_details_service
      "getuserdetails"
    end

    def update_user_service
      "updateuser"
    end

    def account_add_address
      "addaddress"
    end

    def account_user_exists
      "checkuserexists"
    end

    def account_update_user_service
      "getupdateuserformat"
    end
  end
end
