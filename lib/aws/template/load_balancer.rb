module AWS
  class Template
    class LoadBalancer
      include Helper

      def initialize(elb)
        @elb = elb
        @load_balancers = nil
      end

      def aws_instance
        @load_balancers
      end

      def create(config_load_balancers, config_subnets, config_security_groups)
        @load_balancers = {}

        # TODO: update listeners setting updates, and support SSL
        config_load_balancers.each do |lb_name, lb_config|
          log("creating lb [#{lb_name}]...", false)

          load_balancer = @elb.load_balancers[lb_name]
          if load_balancer.exists?
            log("already exists, skipping [#{load_balancer.dns_name}]")

            log("updating health check configuration [#{lb_config["health_check"]}]...", false)
            load_balancer.configure_health_check(lb_config["health_check"])
            log("ok")

            @load_balancers[lb_name] = load_balancer
            next
          end

          # JSON <-> Hash tweaks
          lb_config["listeners"].each_index do |i|
            lb_config["listeners"][i] = normalize(lb_config["listeners"][i])
          end
          lb_config["health_check"] = normalize(lb_config["health_check"])

          lb_options = {}
          lb_options[:listeners] = lb_config["listeners"]
          lb_options[:availability_zones] = []
          lb_options[:subnets] = []
          config_subnets["public"].each do |subnet_name, subnet_cidr|
            subnet_id = config_subnets["cidr"][subnet_cidr]
            lb_options[:subnets] << subnet_id
            # lb_options[:availability_zones] << @vpc.subnets[subnet_id].availability_zone_name
            break # only 1 subnet allowed
          end
          log("(associating with public subnets: #{lb_options[:subnets]})...", false)
          lb_options[:security_groups] = []
          lb_options[:security_groups] << config_security_groups[lb_config["security_groups"]]["id"]
          log("(associating with security groups: #{lb_options[:security_groups]})...", false)
          lb_options[:scheme] = "internet-facing"

          load_balancer = @elb.load_balancers.create(lb_name, lb_options)

          log("updating health check configuration [#{lb_config["health_check"]}]...", false)
          load_balancer.configure_health_check(lb_config["health_check"])
          log("ok")

          @load_balancers[lb_name] = load_balancer

          log("ok [#{load_balancer.dns_name}]")
        end
      end

      protected
      def normalize(options)
        symbol_map = {
          "http" => true,
          "https" => true,
          "port" => true,
          "protocol" => true,
          "instance_port" => true,
          "instance_protocol" => true,
          "interval" => true,
          "target" => true,
          "healthy_threshold" => true,
          "timeout" => true,
          "unhealthy_threshold" => true,
        }
        options.keys.each {|k| options[k.to_sym] = options.delete(k) if symbol_map[k]}
        options.each do |k, v|
          options[k] = v.to_sym if symbol_map[v]
        end

        return options
      end

    end
  end
end
