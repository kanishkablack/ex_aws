defmodule ExAws.Dynamo.Adapter do
  use Behaviour

  @moduledoc """
  The purpose of this module is to surface the ExAws.Dynamo API with a single
  configuration chosen, such that it does not need passed in with every request.

  Usage:
  ```
  defmodule MyApp.Dynamo do
    use ExAws.Dynamo.Adapter, otp_app: :my_otp_app
  end
  ```

  In your config
  ```
  config :my_otp_app, ExAws,
    kinesis:  [], # kinesis config goes here
    dynamodb: [], # you get the idea
  ```

  You can now use MyApp.Dynamo as the root module for the Dynamo api without needing
  to pass in a particular configuration.
  This enables different otp apps to configure their AWS configuration separately.

  The alignment with a particular OTP app however is entirely optional.
  The following also works:

  ```
  defmodule MyApp.Dynamo do
    use ExAws.Dynamo.Adapter

    def config do
      [
        dynamodb: [], # Config goes here
      ]
    end
  end
  ```

  This is in fact how the functions in ExAws.Dynamo that do not require a config work.
  Default config values can be found in ExAws.Config

  http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_Operations.html
  """

  ## Tables
  ######################

  @doc "List tables"
  defcallback list_tables()

  @doc "Create table"
  defcallback create_table(
    table_name      :: iodata,
    primary_key     :: iodata,
    key_definitions :: Keyword.t,
    read_capacity   :: pos_integer,
    write_capacity  :: pos_integer)

  @doc "Create table with indices"
  defcallback create_table(
    table_name      :: iodata,
    primary_key     :: iodata,
    key_definitions :: [%{}],
    read_capacity   :: pos_integer,
    write_capacity  :: pos_integer,
    global_indexes  :: %{},
    local_indexes   :: %{})

  @doc "Describe table"
  defcallback describe_table(name :: iodata)

  @doc "Update Table"
  defcallback update_table(name :: iodata, attributes :: %{})

  @doc "Delete Table"
  defcallback delete_table(table :: iodata)

  ## Records
  ######################

  @doc "Scan table"
  defcallback scan(table_name :: iodata)
  defcallback scan(table_name :: iodata, opts :: %{})

  @doc """
  Stream records from table

  Same as scan/1,2 but the records are a stream which will automatically handle pagination
  """
  defcallback stream_scan(table_name :: iodata)
  defcallback stream_scan(table_name :: iodata, opts :: %{})

  @doc "Query Table"
  defcallback query(table_name :: iodata, key_conditions :: %{})
  defcallback query(table_name :: iodata, key_conditions :: %{}, opts :: %{})

  @doc """
  Get up to 100 items (16mb)

  Map of table names to request parameter maps.
  http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchGetItem.html
  """
  defcallback batch_get_item(%{String.t => %{}})

  @doc """
  Put or delete up to 25 items (16mb)

  Map of table names to request parameter maps.
  http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchWriteItem.html
  """
  defcallback batch_write_item(%{String.t => %{}})

  @doc "Put item in table"
  defcallback put_item(table_name :: iodata, record :: %{})

  @doc "Get item from table"
  defcallback get_item(table_name :: iodata, primary_key_value :: iodata)

  @doc """
  Update item in table

  For update_args format see
  http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_UpdateItem.html
  """
  defcallback update_item(table_name :: iodata, primary_key_value :: iodata, update_args :: %{})

  @doc "Delete item in table"
  defcallback delete_item(table_name :: iodata, primary_key_value :: iodata)

  defcallback config() :: Keyword.t

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, behavior_module: __MODULE__] do
      @otp_app Keyword.get(opts, :otp_app)
      @behaviour behavior_module
      alias ExAws.Dynamo

      @doc false
      def list_tables do
        Dynamo.list_tables(__MODULE__)
      end

      @doc false
      def create_table(name, primary_key, key_definitions, read_capacity, write_capacity) do
        Dynamo.create_table(__MODULE__, name, primary_key, key_definitions, read_capacity, write_capacity)
      end

      @doc false
      def create_table(name, key_schema, key_definitions, read_capacity, write_capacity, global_indexes, local_indexes) do
        Dynamo.create_table(__MODULE__, name, key_schema, key_definitions, read_capacity, write_capacity, global_indexes, local_indexes)
      end

      @doc false
      def describe_table(name) do
        Dynamo.describe_table(__MODULE__, name)
      end

      @doc false
      def update_table(name, attributes) do
        Dynamo.update_table(__MODULE__, name, attributes)
      end

      @doc false
      def delete_table(table) do
        Dynamo.delete_table(__MODULE__, table)
      end

      @doc false
      def scan(name, opts \\ %{}) do
        Dynamo.scan(__MODULE__, name, opts)
      end

      @doc false
      def stream_scan(name, opts \\ %{}) do
        Dynamo.Lazy.stream_scan(__MODULE__, name, opts)
      end

      @doc false
      def query(name, key_conditions, opts \\ %{}) do
        Dynamo.query(__MODULE__, name, key_conditions, opts)
      end

      @doc false
      def batch_get_item(data) do
        Dynamo.batch_get_item(__MODULE__, data)
      end

      @doc false
      def put_item(name, record) do
        Dynamo.put_item(__MODULE__, name, record)
      end

      @doc false
      def batch_write_item(data) do
        Dynamo.batch_write_item(__MODULE__, data)
      end

      @doc false
      def get_item(name, primary_key) do
        Dynamo.get_item(__MODULE__, name, primary_key)
      end

      @doc false
      def update_item(table_name, primary_key, update_args) do
        Dynamo.update_item(__MODULE__, table_name, primary_key, update_args)
      end

      @doc false
      def delete_item(name, primary_key) do
        Dynamo.delete_item(__MODULE__, name, primary_key)
      end

      @doc false
      def service do
        :dynamodb
      end

      @doc false
      def config_root, do: Application.get_env(@otp_app, :ex_aws)

      @doc false
      def config do
        __MODULE__ |> ExAws.Config.get
      end

      defoverridable config: 0, config_root: 0
    end
  end

end
