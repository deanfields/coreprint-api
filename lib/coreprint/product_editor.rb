module CorePrint
  class ProductEditor < ApiResource

    attr_accessor :json, :editorvesion, :editordragpanels

    def load
       data = ApiResource.ensure_array @account.request(:get, product_properties_service, { :productid => self.productid })
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

        def product_properties_service
      "geteditor"
    end
  end
end
