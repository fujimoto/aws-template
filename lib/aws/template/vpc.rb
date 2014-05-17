module AWS
  class Template
    class VPC
      include Helper

      def initialize(ec2)
        @ec2 = ec2
        @vpc = nil
      end

      def aws_instance
        @vpc
      end

      def create(vpc_name, vpc_cidr)
        log("creating VPC [#{vpc_name}]...", false)

        vpc_id = resource_from_tag(@ec2.vpcs, "Name", vpc_name)
        if vpc_id
          log("already exists, skipping [#{vpc_id}]")
          return @vpc = @ec2.vpcs[vpc_id]
        end

        vpc_options = {
          :instance_tenancy => :default,
        }
        @vpc = @ec2.vpcs.create(vpc_cidr, vpc_options)
        @vpc.add_tag("Name", {:value => vpc_name})

        log("ok [#{@vpc.id}]")

        return @vpc
      end
    end
  end
end
