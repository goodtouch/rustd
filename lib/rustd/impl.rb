module Rustd
  module Impl
    class DiagnosticError < StandardError
      attr_reader :diagnostic
      def initialize(diagnostic)
        @diagnostic = diagnostic
      end

      def to_s = diagnostic.to_s
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def impl(trait, &required_methods_definitions)
        include trait

        mod = Module.new
        mod.module_eval(&required_methods_definitions)

        required_methods = trait::RequiredMethods.instance_methods(false)
        defined_methods = mod.instance_methods(false)

        missing_methods = required_methods - defined_methods
        wrong_methods = defined_methods - required_methods

        unless missing_methods.empty?
          # TODO: use Diagnostics::AnyDiagnostic::TraitImplMissingAssocItems?, aka:
          # diag = Diagnostics::AnyDiagnostic::TraitImplMissingAssocItems.new(
          #   file: caller_locations(1, 1).first.path,
          #   missing: missing_methods
          # ).to_diag
          file = caller_locations(1, 1).first.path
          missing = missing_methods.sort.map(&:to_s).join(', ')
          raise DiagnosticError.new("not all `#{trait}` items implemented in #{file}, missing: #{missing}")
        end

        unless wrong_methods.empty?
          # TODO: use Diagnostics::AnyDiagnostic::TraitImplRedundantAssocItems?, aka:
          # diag = Diagnostics::AnyDiagnostic::TraitImplRedundantAssocItems.new(
          #   file: caller_locations(1, 1).first.path,
          #   trait_: trait,
          #   assoc_item: wrong_method
          # ).to_diag
          file = caller_locations(1, 1).first.path
          wrong = wrong_methods.sort.map(&:to_s).join(', ')
          raise DiagnosticError.new("methods implemented in #{file} that are not member of `#{trait}`: #{wrong}")
        end

        class_eval(&required_methods_definitions)
      end
    end
  end
end
