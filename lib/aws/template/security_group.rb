module AWS
  class Template
    class SecurityGroup
      include Helper

      def initialize(ec2)
        @ec2 = ec2
        @security_groups = nil
      end

      def aws_instance
        @security_groups
      end

      def create(vpc, config_security_groups, config_ssh_source)
        @security_groups = {}

        config_security_groups.each do |s_name, s_config|
          log("creating security group [#{s_name}]...", false)
          security_group_id = resource_from_tag(vpc.security_groups, "Name", s_name)

          s = nil
          if security_group_id
            log("already exists, skipping [#{security_group_id}]")
            s = vpc.security_groups[security_group_id]
          else
            security_group_options = {
              :description => s_config[:description],
            }
            s = vpc.security_groups.create(s_name, security_group_options)
            s.add_tag("Name", {:value => s_name})

            log("ok [#{s.id}]")
          end
          @security_groups[s_name] = s

          log("clearing current security settings [#{s.id}]...", false)
          s.ingress_ip_permissions.each do |i|
            log("(#{i.protocol} / #{i.port_range} / #{i.ip_ranges})", false)
            i.revoke()
          end
          log("...ok")

          if s_config["icmp"]
            log("allow (:icmp / #{s_config[:icmp]}) [#{s.id}]...", false)
            s.allow_ping(s_config["icmp"])
            log("ok")
          end
          if s_config["tcp"]
            s_config["tcp"].each do |i|
              if i["port"] == 22
                i["ip"] = config_ssh_source
              end
              i["port"] = parse_port_range(i["port"])

              log("allow (:tcp / #{i["port"]} / #{i["ip"]}) [#{s.id}]...", false)
              s.authorize_ingress(:tcp, i["port"], i["ip"])
              log("ok")
            end
          end
          if s_config["udp"]
            s_config["udp"].each do |i|
              i["port"] = parse_port_range(i["port"])

              log("allow (:udp / #{i["port"]} / #{i["ip"]}) [#{s.id}]...", false)
              s.authorize_ingress(:udp, i["port"], i["ip"])
              log("ok")
            end
          end
        end
      end

      def destroy(config_security_groups)
        config_security_groups.each do |s_name, s_config|
          log("deleting security group [#{s_name}]...", false)
          security_group_id = resource_from_tag(@ec2.security_groups, "Name", s_name)

          if security_group_id.nil?
            log("already deleted, skipping")
            next
          end

          s = @ec2.security_groups[security_group_id]
          s.delete
          log("ok")
        end
      end

      protected
      def parse_port_range(port_range)
        if /^(?<range_from>\d+)\.\.(?<range_to>\d+)$/ =~ port_range.to_s
          return range_from..range_to
        else
          return port_range
        end
      end

    end
  end
end
