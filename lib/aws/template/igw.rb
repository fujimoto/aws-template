module AWS
  class Template
    class IGW
      include Helper

      def initialize(ec2)
        @ec2 = ec2
        @igw = nil
      end

      def aws_instance
        @igw
      end

      def create(vpc, igw_name)
        log("creating internet gateway [#{igw_name}]...", false)

        igw_id = resource_from_tag(@ec2.internet_gateways, "Name", igw_name)
        if igw_id
          log("already exists, skipping [#{igw_id}]")
          @igw = @ec2.internet_gateways[igw_id]
        else
          @igw = @ec2.internet_gateways.create()
          @igw.add_tag("Name", {:value => igw_name})

          log("ok [#{@igw.id}]")
        end

        log("attaching internet gateway to vpc...", false)
        if vpc.internet_gateway.nil?
          vpc.internet_gateway = @igw
          log("ok")
        elsif vpc.internet_gateway.id == @igw.id
          log("already attached, skipping")
        else
          log("different gateway is attached, replacing [#{vpc.internet_gateway.id} -> #{@igw.id}]...", false)
          vpc.internet_gateway = @igw
          log("ok")
        end
      end

      def destroy(vpc_name, igw_name)
        vpc_id = resource_from_tag(@ec2.vpcs, "Name", vpc_name)
        vpc = vpc_id.nil? ? nil : @ec2.vpcs[vpc_id]

        log("deleting internet gateway [#{igw_name}]...", false)
        igw_id = resource_from_tag(@ec2.internet_gateways, "Name", igw_name)
        if igw_id.nil?
          log("already deleted, skipping")
          return
        end

        igw = @ec2.internet_gateways[igw_id]

        if vpc
          log("(detaching from VPC...", false)
          igw.detach(vpc)
          log("ok)...", false)
        end

        igw.delete
        log("ok")
      end

    end
  end
end
