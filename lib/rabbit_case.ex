defmodule GenAMQP.RabbitCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the rabbit mq.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use AMQP

      def rmq_open(uri) do
        AMQP.Connection.open(uri)
      end

      def setup_out_queue(conn, out_queue, out_exchange) do
        {:ok, chan} = AMQP.Channel.open(conn)
        AMQP.Queue.declare(chan, out_queue)
        AMQP.Queue.bind(chan, out_queue, out_exchange, [routing_key: "#"])
        AMQP.Channel.close(chan)
      end

      def setup_in_queue(conn, in_queue, in_exchange) do
        {:ok, chan} = AMQP.Channel.open(conn)
        AMQP.Queue.declare(chan, in_queue)
        AMQP.Exchange.topic(chan, in_exchange, durable: true)
        AMQP.Queue.bind(chan, in_queue, in_exchange, [routing_key: "#"])
        AMQP.Channel.close(chan)
      end

      def get_message_from_queue(context) do
        {:ok, chan} = AMQP.Channel.open(context[:rabbit_conn])
        {:ok, payload, _meta} = AMQP.Basic.get(chan, context[:out_queue])
        {:ok, Poison.decode!(payload)}
      end

      def purge_queues(uri, queues) do
        {:ok, conn} = rmq_open(uri)
        Enum.each(queues, &purge_queue(conn, &1))
        AMQP.Connection.close(conn)
      end

      def purge_queue(conn, queue) do
        {:ok, chan} = AMQP.Channel.open(conn)
        AMQP.Queue.purge(chan, queue)
        AMQP.Channel.close(chan)
      end

      def out_queue_count(context) do
        queue_count(context, :out_queue)
      end

      def dl_queue_count(context) do
        queue_count(context, :dl_queue)
      end

      defp queue_count(context, queue) do
        {:ok, chan} = AMQP.Channel.open(context[:rabbit_conn])
        {:ok, %{message_count: count}} =
          AMQP.Queue.declare(chan, context[queue], [passive: true])
        AMQP.Channel.close(chan)
        count
      end
    end
  end
end