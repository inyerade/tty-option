# frozen_string_literal: true

require_relative "../lib/tty-option"

module Network
  class Create
    include TTY::Option

    usage do
      header "CLI app v1.2.3"

      command "create"

      desc "Create a network"

      example "The following creates a bridge network:",
              "  $ network create -d bridge my-bridge-network"

      example <<~EOS
      The following creates a bridge network with a subnet:
        $ network create --driver=bridge --subnet=192.168.0.0/16 br0
      EOS

      footer "Run 'network create --help' for more information on a command."
    end

    argument :network do
      required
      desc "Name for the new network"
    end

    flag :attachable do
      desc "Enable manual container attachment"
    end

    flag :config_only do
      desc "Create a configuration only network"
    end

    option :driver do
      short "-d"
      long "--driver string"
      default "bridge"
      desc "Driver to manage the Network"
    end

    option :gateway do
      long "--gateway strings"
      convert :list
      desc "IPv4 or IPv6 Gateway for the master subnet"
    end

    option :label do
      long "--label list"
      convert :list
      desc "Set metadata on a network"
    end

    option :options do
      short "-o"
      long "--opt map"
      convert :map
      default({})
      desc "Set driver specific options"
    end

    option :subnet do
      long "--subnet strings"
      convert :list
      desc "Subnet in CIDR format that represents a network segment"
    end

    def execute
      p params.to_h
    end
  end
end

create = Network::Create.new

create.parse(%w[--attachable my-network --gateway host --driver overlay --opt a:1 b:2])

create.execute

puts create.help
