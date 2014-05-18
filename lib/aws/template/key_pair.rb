module AWS
  class Template
    class KeyPair
      include Helper

      def initialize(ec2)
        @ec2 = ec2
        @key_pair = nil
      end

      def aws_instance
        @key_pair
      end

      def create(key_pair_name, key_pair_local_path)
        log("creating key pair [#{key_pair_name}]...", false)

        key_pair = nil
        if @ec2.key_pairs[key_pair_name].exists?
          log("already exists, skipping (no private key file created in this case)")
          return @key_pair = @ec2.key_pairs[key_pair_name]
        else
          @key_pair = @ec2.key_pairs.create(key_pair_name)
          log("ok")
        end

        log("updating local key file [#{key_pair_local_path}]...", false)
        File.open(key_pair_local_path, "w") do |f|
          f.write(@key_pair.private_key)
        end
        File.chmod(0100600, key_pair_local_path)
        log("ok")
      end

      def destroy(key_pair_name)
        log("deleting key pair [#{key_pair_name}]...", false)

        key_pair = @ec2.key_pairs[key_pair_name]
        if key_pair.exists? == false
          log("already deleted, skipping (local key files will not be deleted)")
          return
        end

        key_pair.delete
        log("ok")
      end

    end
  end
end
