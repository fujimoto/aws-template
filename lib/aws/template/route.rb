module AWS
  class Template
    class Route
      include Helper

      def initialize(ec2)
        @ec2 = ec2
        @route = nil
      end

      def aws_instance
        @route
      end

      def create(vpc, igw, config_subnets)
        main_route_table_name = "route-main"

        # name if main route table does not have tags
        log("adding tag to main route table [#{main_route_table_name}]...", false)
        if vpc.route_tables.main_route_table.tags.to_h['Name'] != main_route_table_name
          vpc.route_tables.main_route_table.add_tag("Name", {:value => "route-main"})
          log("ok")
        else
          log("already set, skipping")
        end

        # route for public subnets
        public_route_table_name = "route-public"
        public_route_cidr = "0.0.0.0/0"
        log("creating route for public subnets [#{public_route_table_name}]...", false)

        route_id = resource_from_tag(vpc.route_tables, "Name", public_route_table_name)
        route = nil
        if route_id
          route = vpc.route_tables[route_id]
          log("already exists, skipping [#{route_id}]")
        else
          route = vpc.route_tables.create()
          route.add_tag("Name", {:value => public_route_table_name})
          log("ok [#{route.id}]")
        end

        log("adding or replacing routing entry for public subnets [#{public_route_cidr} -> #{igw.id}]...", false)
        has_entry = false
        route.routes do |r|
          if r.destination_cidr_block == public_route_cidr
            has_entry = true
            break
          end
        end

        route_options = {
          :internet_gateway => igw.id
        }
        if has_entry
          route.replace_route(public_route_cidr, route_options)
        else
          route.create_route(public_route_cidr, route_options)
        end
        log("ok")

        config_subnets["public"].each do |subnet_name, subnet_cidr|
          subnet_id = config_subnets["cidr"][subnet_cidr]
          log("associating route to public subnets [#{route.id} -> #{subnet_cidr} (#{subnet_id})]...", false)
          vpc.subnets[subnet_id].set_route_table(route)
          puts "ok"
        end
      end

      def associate(vpc, eni, route_table_name, route_cidr)
        log("disabling ENI source/dest check [#{eni.id}]...", false)
        eni.source_dest_check = false
        log("ok")

        route_id = resource_from_tag(vpc.route_tables, "Name", route_table_name)
        route = vpc.route_tables[route_id]

        log("adding or replacing routing entry for all subnets [#{route_cidr} -> #{eni.id} (#{route_id})]...", false)
        has_entry = false
        route.routes do |r|
          if r.destination_cidr_block == route_cidr
            has_entry = true
            break
          end
        end

        route_options = {
          :network_interface => eni.id
        }
        if has_entry
          route.replace_route(route_cidr, route_options)
        else
          route.create_route(route_cidr, route_options)
        end
        log("ok")
      end

    end
  end
end
