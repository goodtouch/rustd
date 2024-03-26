require 'minitest/autorun'
require 'rustd'

class ImplTest < Minitest::Test
  module ZeroWing
    module RequiredMethods # or: required_methods do
      def bases
      end

      def survive
      end
    end

    def transcript
      <<~TRANSCRIPT
        Mechanic: Somebody set up us the bomb.
        Operator: Main screen turn on.
        CATS: #{bases}.
        CATS: #{survive}.
        Captain: Move 'ZIG'.
        Captain: For great justice.
      TRANSCRIPT
    end
  end

  def test_missing_item_err
    error = assert_raises(Rustd::Impl::DiagnosticError) do
      Class.new do
        include Rustd::Impl

        impl ZeroWing do
          def bases
            'All your base are belong to us'
          end
        end
      end
    end

    assert_equal("not all `ImplTest::ZeroWing` items implemented in #{__FILE__}, missing: survive", error.message)
  end

  def test_wrong_methods_err
    error = assert_raises(Rustd::Impl::DiagnosticError) do
      Class.new do
        include Rustd::Impl

        impl ZeroWing do
          def bases
            'All your base are belong to us'
          end

          def survive
            'You have no chance to survive make your time'
          end

          def operator
            'Operator: Main screen turn on.'
          end

          def justice
            'Captain: For great justice.'
          end
        end
      end
    end

    assert_equal("methods implemented in #{__FILE__} that are not member of `ImplTest::ZeroWing`: justice, operator", error.message)
  end
end
