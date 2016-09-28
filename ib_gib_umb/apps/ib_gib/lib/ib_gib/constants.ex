defmodule IbGib.Constants do
  @moduledoc """
  This module contains constants used in various aspects throughout the
  applications. Each function is a scope of constants and contains instructions
  for consuming the constants in a module.
  """

  @doc """
  Use this with `use IbGib.Constants, :ib_gib`
  """
  def ib_gib do
    # defmacro delim do
    #   quote do: "^"
    # end
    quote do
      # if change, must also change in regex below
      @delim "^"
      @root_ib_gib "ib#{@delim}gib"
      @error_gib "error#{@delim}gib"

      defp min_id_length, do: 1
      defp max_id_length, do: 76
      defp min_ib_gib_length, do: 3 # min + delim + min
      defp max_ib_gib_length, do: 153 # max + delim + max
      defp max_data_size, do: 10_240_000 # 10 MB max internal data
      # one or more word chars, underscore, dash
      defp regex_valid_ib, do: ~r/^[\w\d_-\s]+$/
      defp regex_valid_gib, do: ~r/^[\w\d]+$/
      # delim hardcoded in!!!!
      defp regex_valid_ib_gib, do: ~r/^[\w\d_-\s]+\^[\w\d]+$/

      @default_dna [@root_ib_gib]
      @default_past [@root_ib_gib]
      @default_ancestor [@root_ib_gib]
      @default_identity [@root_ib_gib]

      @default_data %{}

      # The following is misnamed. It's the default_rel8ns when performing
      # a rel8 transform. Will refactor.
      @default_rel8ns ["rel8d"]

      # This "stamp" added to gib means that we have generated the ib_gib,
      # and not a user.
      @gib_stamp "ibGib"

      @default_transform_options %{"gib_stamp" => "false"}
      @default_transform_src "[src]"
      @default_fork_dest_ib "[src.ib]"

      # This key prefix is a helper that indicates some meta action for the
      # corresponding key/value entry in a map.
      #
      # ATOW: 2016/08/10
      # Use case for this is that I want to be able to delete/edit an existing
      # key via a mut8. So if an ib_gib's data has `"a" => "a value"` and I want
      # to delete that key/value pair.
      defp map_key_meta_prefix, do: "meta__"
      defp rename_operator, do: ">rename>"

      # This is used for creating identities themselves when the user is not
      # yet authenticated. You need identities to create ib_gib, but you don't
      # have an ib_gib identity before doing so! Definitely an attack vector
      # here, which I'm thinking on. But I think the idea is to restrict the
      # use of this identity to only forking identity^gib and nothing else.
      # This way, whatever is forked we already consider low trust anyway, as
      # this is going to be the "lowest" layer of identity (anon session).
      # We make it an atom so it doesn't pattern match against strings.
      # @bootstrap_identity_ib_gib "bootstrap_identity#{@delim}gib"
      # I'm making this the root `ib^gib` because it makes sense conceptually.
      # I certainly don't know if it's definitely the right thing to do!
      @bootstrap_identity_ib_gib @root_ib_gib
      @identity_ib_gib "identity#{@delim}gib"
    end
  end

  def validation do
    quote do
      @max_comment_text_size 127
    end
  end

  # For use with testing.
  def test do
    quote do
      @test_identities_1 [
        @bootstrap_identity_ib_gib,
        "test identity1#{@delim}ibGib_gib_ibGib"
      ]
      @test_identities_2 [
        @bootstrap_identity_ib_gib,
        "test identity1#{@delim}ibGib_gib_ibGib",
        "test identity2222222222#{@delim}ibGib_gib_ibGib"
      ]
    end
  end

  @doc """
  Use this with `use IbGib.Constants, :error_msgs`
  """
  def error_msgs do
    quote do
      defp emsg_invalid_relations do
        "Rel8ns are invalid. :-/"
      end

      defp emsg_invalid_data do
        "Data is invalid. :-O"
      end

      defp emsg_invalid_id_length do
        "invalid id length"
      end

      defp emsg_invalid_unknown_src_maybe do
        "invalid. unknown src maybe, maybe not an array of string"
      end

      defp emsg_invalid_data_value(value) do
        "invalid data value: #{inspect value}"
      end

      defp emsg_unknown_field do
        "Unknown field. Expected either :data or :rel8ns."
      end

      defp emsg_hash_problem do
        "There was a problem hashing the given value."
      end

      defp emsg_invalid_args(args) do
        "Invalid args: #{inspect args}"
      end

      defp emsg_query_result_count(count) do
        "Unexpected query result count: #{count}"
      end

      def emsg_only_instance_bootstrap_identity_from_identity_gib do
        "The bootstrap identity can only instance the identity#{@delim}gib. All other transforms must have a valid identity."
      end

      def emsg_invalid_identity_ib_gibs do
        "Invalid identity given."
      end

      def emsg_invalid_authorization(expected, actual) do
        "Authorization level not met. Expected: #{inspect expected}. Actual: #{inspect actual}"
      end

      def emsg_invalid_rel8_src_mismatch(src_ib_gib, a_ib_gib) do
        "A rel8 transform was attempted, but the src_ib_gib (#{src_ib_gib}) does not match the ib_gib which is transforming (#{a_ib_gib})."
      end
    end
  end

  # def query do
  #   quote do
  #     def ib_search_methods, do: @ib_search_methods
  #   end
  # end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
