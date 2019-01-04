# frozen_string_literal: true
require 'active_support/concern'
require 'active_support/core_ext/class/attribute'

module ActiveRecordCustomPreloader
  module ModelPatch
    extend ActiveSupport::Concern

    included do
      class_attribute :_custom_loaders, instance_writer: false
      class_attribute :_default_custom_loader_class, instance_accessor: false
      self._custom_loaders = {}
      self._default_custom_loader_class = 'ActiveRecordCustomerPreloader::Preloader'.freeze

      # clear custom preloaded values on model instance reload
      def reload(*)
        clear_custom_preloaded_values
        super
      end
    end

    class_methods do
      # add custom preloader for ActiveRecord model
      # name <Symbol> name of loader [required]
      # args <Hash> options that will be propagated to preloader (except :skip_methods and :class_name)
      #   args[:skip_methods] <Boolean> will not create method "#{name}" for instance if true (default false)
      #   args[:class_name] <String> class name of preloader (default 'ActiveRecord::CustomerPreloader::Preloader')
      #
      def add_custom_loader(name, args = {})
        skip_methods = args.delete(:skip_methods)
        class_name = args.delete(:class_name) || _default_custom_loader_class
        self._custom_loaders = _custom_loaders.merge(name.to_sym => {
            class_name: class_name,
            args: args
        })

        define_method(name) do
          _custom_preloaded_value(name)
        end unless skip_methods
      end

      # find custom loader by name
      # returns instance of custom loader
      def custom_loader_for(name, options = {})
        opts = _custom_loaders[name]
        raise Error, "custom preloader #{name.inspect} does not exist" if opts.nil?
        klass = opts[:class_name].safe_constantize
        raise Error, "custom preloader klass #{opts[:class_name]} can't be found" if klass.nil?
        klass.new self, name, opts[:args].merge(options)
      end

      # check if class has custom loader for name
      def has_custom_loader?(name)
        _custom_loaders.key?(name)
      end
    end

    ## Instance Methods

    # clear custom preloaded values
    def clear_custom_preloaded_values
      @_custom_preloaded_values = nil
    end

    # clear particular custom preloaded value
    def clear_custom_preloaded_value(name)
      raise Error, "custom preloader #{name.inspect} does not exist" unless _custom_loaders.key?(name)
      _custom_preloaded_values.delete(name)
    end

    # sets custom preloaded value for name
    def _set_custom_preloaded_value(name, value)
      _custom_preloaded_values[name] = value
    end

    # returns Hash that stores cached custom preloaded values
    def _custom_preloaded_values
      @_custom_preloaded_values ||= {}
    end

    # fetch if necessary and return custom preloaded value for name
    def _custom_preloaded_value(name)
      raise ArgumentError, "custom preloader #{name.inspect} does not exist" unless _custom_loaders.key?(name)
      unless _custom_preloaded_values.key?(name)
        custom_loader_for(name).preload([self])
      end
      _custom_preloaded_values[name]
    end
  end
end
