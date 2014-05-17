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

        @r53.hosted_zones.each do |h|
          if h.name == zone_name
            @hosted_zone = h
            log("already exists, skipping [#{h.id}]")
            break
          end
        end

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

      def add_a_record(name, public_ip, ttl = 300)
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

      def add_a_record_lb(load_balancers, lb_name, lb_config)
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

    end
  end
end
