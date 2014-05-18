module AWS
  class Template
    class R53
      include Helper

      def initialize(r53)
        @r53= r53
        @hosted_zone = nil
      end

      def aws_instance
        @hosted_zone
      end

      def create(zone_name)
        log("creating zones [#{zone_name}]...", false)

        @hosted_zone = from_name(zone_name)
        log("already exists, skipping [#{@hosted_zone.id}]") if @hosted_zone

        hosted_zone_created = false
        if @hosted_zone.nil?
          @hosted_zone = @r53.hosted_zones.create(zone_name, { :comment => "DNS records for #{zone_name}" })
          hosted_zone_created = true
          log("ok [#{@hosted_zone.id}]")
        end

        rrsets = @hosted_zone.rrsets
        if hosted_zone_created
          r = rrsets[zone_name, "NS"]
          log("--- hosted zone created, add following to your name servers ---")
          r.resource_records.each do |v|
            puts v[:value]
          end
          log("--- end ---")
        end
      end

      def destroy(zone_name)
        log("deleting zones [#{zone_name}]...", false)

        @hosted_zone = from_name(zone_name)
        if @hosted_zone.nil?
          log("already deleted, skipping")
          return
        end

        @hosted_zone.delete
        log("ok")
      end

      def add_a_record(zone_name, name, public_ip, ttl = 300)
        @hosted_zone = from_name(zone_name)
        if @hosted_zone.nil?
          log("warning: no such zone [#{zone_name}]...skip adding record [#{name}]")
          return
        end

        rrsets = @hosted_zone.rrsets
        r = rrsets[name, "A"]
        if r.exists?
          log("updating records [#{r.name}, #{r.resource_records} -> #{public_ip}]...", false)
          r.resource_records = [ {:value => public_ip} ]
          r.update
          log("ok")
        else
          log("adding records [#{name} -> #{public_ip}]...", false)
          r = rrsets.create(name, "A", {:ttl => ttl, :resource_records => [{:value => public_ip}]})
          log("ok")
        end
      end

      def delete_a_record(zone_name, name)
        log("deleting records [#{name}]...", false)
        @hosted_zone = from_name(zone_name)
        if @hosted_zone.nil?
          log("zone alreday deleted, skipping")
          return
        end

        rrsets = @hosted_zone.rrsets
        r = rrsets[name, "A"]
        if r.exists? == false
          log("record alreday deleted, skipping")
          return
        end

        r.delete
        log("ok")
      end

      def add_a_record_lb(zone_name, load_balancers, lb_name, lb_config)
        @hosted_zone = from_name(zone_name)
        if @hosted_zone.nil?
          log("warning: no such zone [#{zone_name}]...skip adding record [#{name}]")
          return
        end

        rrsets = @hosted_zone.rrsets

        zone_name = lb_config["zone_name"]
        dns_name = lb_config["dns_name"]
        hosted_zone_id = load_balancers[lb_name].canonical_hosted_zone_name_id

        r = rrsets[zone_name, "A"]
        if r.exists?
          log("updating alias records [#{zone_name} -> #{dns_name}]...", false)
          r.alias_target = {:hosted_zone_id => hosted_zone_id, :dns_name => dns_name, :evaluate_target_health => false}
          r.update
          log("ok")
        else
          log("adding alias records [#{zone_name} -> #{dns_name}]...", false)
          r = rrsets.create(zone_name, "A", {:alias_target => {:hosted_zone_id => hosted_zone_id, :dns_name => dns_name, :evaluate_target_health => false}})
          log("ok")
        end
      end

      def delete_a_record_lb(zone_name, lb_name, lb_config)
        log("deleting records for [#{lb_name}]...", false)
        @hosted_zone = from_name(zone_name)
        if @hosted_zone.nil?
          log("zone alreday deleted, skipping")
          return
        end

        rrsets = @hosted_zone.rrsets

        zone_name = lb_config["zone_name"]
        dns_name = lb_config["dns_name"]

        r = rrsets[zone_name, "A"]
        if r.exists? == false
          log("record already deleted, skipping")
          return
        end

        r.delete
        log("ok")
      end

      protected
      def from_name(zone_name)
        @r53.hosted_zones.each do |h|
          if h.name == zone_name
            return h
          end
        end

        return nil
      end

    end
  end
end
