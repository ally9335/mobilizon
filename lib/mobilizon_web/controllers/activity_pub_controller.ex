# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/activity_pub/activity_pub_controller.ex

defmodule MobilizonWeb.ActivityPubController do
  use MobilizonWeb, :controller
  alias Mobilizon.{Actors, Actors.Actor, Events}
  alias Mobilizon.Events.{Event, Comment}
  alias MobilizonWeb.ActivityPub.{ObjectView, ActorView}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Utils
  alias Mobilizon.Service.Federator

  require Logger

  action_fallback(:errors)

  @doc """
  Renders an Actor ActivityPub's representation
  """
  @spec actor(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def actor(conn, %{"name" => name}) do
    with {status, %Actor{} = actor} when status in [:ok, :commit] <-
           Actors.get_cached_local_actor_by_name(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("actor.json", %{actor: actor}))
    else
      {:ignore, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Renders an Event ActivityPub's representation
  """
  @spec event(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def event(conn, %{"uuid" => uuid}) do
    with {status, %Event{} = event} when status in [:ok, :commit] <-
           Events.get_cached_event_full_by_uuid(uuid),
         true <- event.visibility in [:public, :unlisted] do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ObjectView.render("event.json", %{event: event |> Utils.make_event_data()}))
    else
      {:ignore, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Renders a Comment ActivityPub's representation
  """
  @spec comment(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def comment(conn, %{"uuid" => uuid}) do
    with {status, %Comment{} = comment} when status in [:ok, :commit] <-
           Events.get_cached_comment_full_by_uuid(uuid) do
      # Comments are always public for now
      # TODO : Make comments maybe restricted
      # true <- comment.public do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ObjectView.render("comment.json", %{comment: comment |> Utils.make_comment_data()}))
    else
      {:ignore, _} ->
        {:error, :not_found}
    end
  end

  def following(conn, %{"name" => name, "page" => page}) do
    with {page, ""} = Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name_with_everything(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("following.json", %{actor: actor, page: page}))
    end
  end

  def following(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name_with_everything(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("following.json", %{actor: actor}))
    end
  end

  def followers(conn, %{"name" => name, "page" => page}) do
    with {page, ""} = Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name_with_everything(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("followers.json", %{actor: actor, page: page}))
    end
  end

  def followers(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name_with_everything(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("followers.json", %{actor: actor}))
    end
  end

  def outbox(conn, %{"name" => name, "page" => page}) do
    with {page, ""} = Integer.parse(page),
         %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("outbox.json", %{actor: actor, page: page}))
    end
  end

  def outbox(conn, %{"name" => name}) do
    with %Actor{} = actor <- Actors.get_local_actor_by_name(name) do
      conn
      |> put_resp_header("content-type", "application/activity+json")
      |> json(ActorView.render("outbox.json", %{actor: actor}))
    end
  end

  # TODO: Ensure that this inbox is a recipient of the message
  def inbox(%{assigns: %{valid_signature: true}} = conn, params) do
    Federator.enqueue(:incoming_ap_doc, params)
    json(conn, "ok")
  end

  # only accept relayed Creates
  def inbox(conn, %{"type" => "Create"} = params) do
    Logger.info(
      "Signature missing or not from author, relayed Create message, fetching object from source"
    )

    ActivityPub.fetch_object_from_url(params["object"]["id"])

    json(conn, "ok")
  end

  def inbox(conn, params) do
    headers = Enum.into(conn.req_headers, %{})

    if String.contains?(headers["signature"], params["actor"]) do
      Logger.error(
        "Signature validation error for: #{params["actor"]}, make sure you are forwarding the HTTP Host header!"
      )

      Logger.error(inspect(conn.req_headers))
    end

    json(conn, "error")
  end

  def errors(conn, {:error, :not_found}) do
    conn
    |> put_status(404)
    |> json("Not found")
  end

  def errors(conn, _e) do
    conn
    |> put_status(500)
    |> json("Unknown Error")
  end
end
