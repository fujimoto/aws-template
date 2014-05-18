module AWS
  class Template
    class Subnet
      include Helper

      def initialize(ec2)
        @ec2 = ec2
        @subnets = nil
      end

      def aws_instance
        @subnets
      end

      def create(vpc, config_subnets)
        @subnets = []

        ["public", "private"].each do |t|
          config_subnets[t].each do |subnet_name, subnet_cidr|
            log("creating subnet [#{subnet_name}]...", false)

            subnet_id = resource_from_tag(vpc.subnets, "Name", subnet_name)
            if subnet_id
              log("already exists, skipping [#{subnet_id}]")
              @subnets << vpc.subnets[subnet_id]
              next
            end

            subnet_options = {}
            subnet = vpc.subnets.create(subnet_cidr, subnet_options)
            subnet.add_tag("Name", {:value => subnet_name})
            @subnets << subnet

            log("ok [#{subnet.id}]")
          end
        end
      end

      def destroy(vpc_name, config_subnets)
        vpc_id = resource_from_tag(@ec2.vpcs, "Name", vpc_name)
        if vpc_id.nil?
          log("VPC already deleted, skip deleting subnets")
          return
        end
        vpc = @ec2.vpcs[vpc_id]

        ["public", "private"].each do |t|
          config_subnets[t].each do |subnet_name, subnet_cidr|
            log("deleting subnet [#{subnet_name}]...", false)

            subnet_id = resource_from_tag(vpc.subnets, "Name", subnet_name)
            if subnet_id.nil?
              log("already deleted, skipping")
              next
            end

            vpc.subnets[subnet_id].delete
            log("ok [#{subnet_id}]")
          end
        end
      end

    end
  end
end
