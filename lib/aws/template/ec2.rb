module AWS
  class Template
    class EC2
      include Helper

      def initialize(ec2)
        @ec2 = ec2
        @instances = nil
      end

      def aws_instance
        @instances
      end

      def create(instance_name, launch_proc)
        @instances = {} if @instances.nil?

        log("launching instances [#{instance_name}]...", false)

        @ec2.instances.each do |machine|
          next if machine.status != :running
          if machine.tags.to_h["Name"] == instance_name
            log("already running, skipping [#{machine.id}]")
            @instances[instance_name] = machine
            return
          end
        end

        launch_proc.call(@ec2)

        machine_id = resource_from_tag(@ec2.instances, "Name", instance_name)
        @instances[instance_name] = @ec2.instances[machine_id]
      end

      def destroy(shutdown_proc)
        shutdown_proc.call(@ec2)
      end

      def eni(instance_name)
        return nil if @instances.nil?
        machine = @instances[instance_name]

        enis = machine.network_interfaces
        return nil if enis.length <= 0

        return enis[0]
      end

    end
  end
end
