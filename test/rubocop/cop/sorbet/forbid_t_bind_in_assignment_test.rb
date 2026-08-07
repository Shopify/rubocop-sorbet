# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTBindInAssignmentTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTBindInAssignment: Do not assign the result of `T.bind`; it also changes the type of its first argument."

        def setup
          @cop = ForbidTBindInAssignment.new
        end

        def test_adds_offense_when_assigning_t_bind_result
          assert_offense(<<~RUBY)
            foo = T.bind(self, Integer)
                  ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            @foo = T.bind(self, Integer)
                   ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            self.foo = T.bind(self, Integer)
                       ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            foo ||= T.bind(self, Integer)
                    ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            foo, bar = T.bind(self, Integer)
                       ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo = T.cast(self, Integer)
            @foo = T.cast(self, Integer)
            self.foo = T.cast(self, Integer)
            foo ||= T.cast(self, Integer)
            foo, bar = T.cast(self, Integer)
          RUBY
        end

        def test_adds_one_offense_for_chained_assignments
          assert_offense(<<~RUBY)
            foo = bar = T.bind(self, Integer)
                        ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo = bar = T.cast(self, Integer)
          RUBY
        end

        def test_allows_t_bind_when_its_result_is_not_assigned
          assert_no_offenses(<<~RUBY)
            T.bind(self, Integer)
            consume(T.bind(self, Integer))
            foo = consume(T.bind(self, Integer))
          RUBY
        end

        def test_ignores_other_bind_methods
          assert_no_offenses(<<~RUBY)
            foo = object.bind(self, Integer)
            foo = T::Private.bind(self, Integer)
          RUBY
        end
      end
    end
  end
end
