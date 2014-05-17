module AWS
  class Template
    module Helper
      def log(s, newline = true)
        # xxx
        if newline
          puts s
        else
          print s
        end
      end

      def resource_from_tag(collection, key, value)
        collection.each do |r|
          if r.tags.to_h[key] == value
            return r.id
          end
        end

        return nil
      end

    end
  end
end
