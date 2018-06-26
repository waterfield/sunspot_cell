module SunspotCell
  module Setup

    def self.included(base)
      base.class_eval do
        alias :sunspot_initialize :initialize unless method_defined?(:sunspot_initialize)
        def initialize(clazz)
          @attachment_field_factories, @attachment_field_factories_cache = *Array.new(8) { Hash.new }
          sunspot_initialize(clazz)
        end

        alias :sunspot_all_field_factories :all_field_factories unless method_defined?(:sunspot_all_field_factories)
        def all_field_factories
          all_field_factories = sunspot_all_field_factories
          all_field_factories.concat(attachment_field_factories)
          all_field_factories
        end

        # Add field_factories for fulltext search on attachments
        #
        # ==== Parameters
        #
        def add_attachment_field_factory(name, options = {}, &block)
          stored = options[:stored]
          field_factory = Sunspot::FieldFactory::Static.new(name, Sunspot::Type::AttachmentType.instance, options, &block)
          @attachment_field_factories[name] = field_factory
          @attachment_field_factories_cache[field_factory.name] = field_factory
          if stored
            @attachment_field_factories_cache[field_factory.name] << field_factory
          end
        end

        def text_fields(field_name)
          text_field =
            if field_factory = @text_field_factories_cache[field_name.to_sym]
              field_factory.build
            else
              if field_factory = @attachment_field_factories_cache[field_name.to_sym]
                field_factory.build
              else
                raise(
                  UnrecognizedFieldError,
                  "No text field configured for #{@class_name} with name '#{field_name}'"
                )
              end
            end
          [text_field]
        end

        #
        # Return all text fields
        #
        def all_text_fields
          text_field_factories.concat(attachment_field_factories).map(&:build)
        end

        def all_attachment_fields
          attachment_field_factories.map(&:build)
        end

        # Get the text field_factories associated with this setup as well as all inherited
        # attachment field_factories
        #
        # ==== Returns
        #
        # Array:: Collection of all text field_factories associated with this setup
        #
        def attachment_field_factories
          collection_from_inheritable_hash(:attachment_field_factories)
        end
      end
    end

  end
end
