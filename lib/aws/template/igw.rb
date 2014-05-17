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

    end
  end
end
