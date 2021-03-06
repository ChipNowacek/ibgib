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

      # defp min_id_length, do: 1
      @min_id_length 1
      @max_id_length 76
      @hash_length 64
      @min_ib_gib_length 3 # min + delim + min
      @max_ib_gib_length 153 # max + delim + max
      @max_data_size 10_240_000 # max internal data size in MB
      # defp max_data_size, do: @max_data_size
      # one or more word chars, underscore, dash
      @regex_valid_ib ~r/^\w[\w\d \-]*(?<![\s])$/
      @regex_valid_gib ~r/^\w+$/
      # delim hardcoded in!!!!
      @regex_valid_ib_gib ~r/^\w[\w\d \-]*(?<![\s])[\^][\w\d]+$/
      @regex_valid_rel8n_name @regex_valid_ib

      @default_dna [@root_ib_gib]
      @default_past [@root_ib_gib]
      @default_ancestor [@root_ib_gib]
      @default_identity [@root_ib_gib]

      @default_data %{}

      # The following is misnamed. It's the default_rel8ns when performing
      # a rel8 transform. Will refactor.
      # @default_rel8ns ["rel8d"]
      @default_rel8ns [@root_ib_gib]

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
      @map_key_meta_prefix "meta__"
      @rename_operator ">rename>"

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
      @identity_type_delim "_"

      @invalid_unrel8_rel8ns ["past", "ancestor", "dna", "identity"]
      @invalid_adjunct_rel8ns ["past", "ancestor", "dna", "identity"]
    end
  end

  def validation do
    quote do
      @min_email_addr_size 5
      @max_email_addr_size 63
      @regex_valid_email_addr ~r/^[\w][\w+\.]*(?<=[\w])[]@[\w][\w\.]*\.[\w]+$/
      @max_comment_text_size 16_384
      @max_tag_text_size 60
      @max_tag_icons_text_size 60
      @min_link_text_size 10 # http://a.b
      @max_link_text_size 255
      @min_query_data_text_size 0
      @max_query_data_text_size 255
      @max_text_size_oy_kind 32
      @max_text_size_oy_filter 1024
    end
  end

  # For use with testing.
  def test do
    quote do
      @test_identities_1 [
        @bootstrap_identity_ib_gib,
        "node_test identity1#{@delim}ibGib_gibyo_ibGib",
        "session_test identity1#{@delim}ibGib_gib_ibGib"
      ]
      @test_identities_2 [
        @bootstrap_identity_ib_gib,
        "node_test identity1#{@delim}ibGib_gibyo_ibGib",
        "session_test identity1#{@delim}ibGib_gib_ibGib",
        "session_test identity2222222222#{@delim}ibGib_gib_ibGib"
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

      def emsg_not_found do
        "The item was not found. :-/"
      end

      def emsg_not_found(what) when is_bitstring(what) do
        "The item (#{what}) was not found. :-/"
      end
      def emsg_not_found(what) do
        "The item (#{inspect what}) was not found. :-/"
      end

      def emsg_hash_mismatch do
        "The hashes do not match."
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
