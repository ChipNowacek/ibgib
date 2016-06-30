# RandomGib

This is a standalone application for some simple and **common** use cases for
getting random stuff. This is not intended to be cryptographically strong.

## Features (aka Functions)
* `one_of(src)`
  * Gets a single thing from some given source. Currently can be a list or
    a string.
  * `RandomGib.Get.one_of("abc_|*&")`
    * `"c"`
  * `RandomGib.Get.one_of([:a, 1, "yo"])`
    * `1`
  * `RandomGib.Get.one_of('char-list_here>yo')`
    * `105`
* `some_of(src)`
  * Gets some (non-empty) subset of a given source. Also can be a list or a string.
  * `RandomGib.Get.some_of("abc_|*&")`
    * `"abc|&"`
  * `RandomGib.Get.some_of([:a, 1, "yo"])`
    * `[:a, "yo"]`
  * `RandomGib.Get.some_of('char-list_here>yo')`
    * `'charlsthereyo'`
* `some_letters(count)`
  * Gets some random (mixed-case) letters of a given `count`.
  * `RandomGib.Get.some_letters(10)`
    * `"juEGDhqRAk"`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add random_gib to your list of dependencies in `mix.exs`:

        def deps do
          [{:random_gib, "~> 0.0.2"}]
        end

  2. Ensure random_gib is started before your application:

        def application do
          [applications: [:random_gib]]
        end
