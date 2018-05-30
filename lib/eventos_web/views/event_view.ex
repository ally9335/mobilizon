defmodule EventosWeb.EventView do
  @moduledoc """
  View for Events
  """
  use EventosWeb, :view
  alias EventosWeb.{EventView, ActorView, GroupView, AddressView}

  def render("index.json", %{events: events}) do
    %{data: render_many(events, EventView, "event_simple.json")}
  end

  def render("show_simple.json", %{event: event}) do
    %{data: render_one(event, EventView, "event_simple.json")}
  end

  def render("show.json", %{event: event}) do
    %{data: render_one(event, EventView, "event.json")}
  end

  def render("event_for_actor.json", %{event: event}) do
    %{id: event.id,
      title: event.title,
      slug: event.slug
    }
  end

  def render("event_simple.json", %{event: event}) do
    %{id: event.id,
      title: event.title,
      slug: event.slug,
      description: event.description,
      begins_on: event.begins_on,
      ends_on: event.ends_on,
      organizer: %{
        username: event.organizer_actor.preferred_username
      },
      type: "Event",
    }
  end

  def render("event.json", %{event: event}) do
    %{id: event.id,
      title: event.title,
      description: event.description,
      begins_on: event.begins_on,
      ends_on: event.ends_on,
      organizer: render_one(event.organizer_actor, ActorView, "acccount_basic.json"),
      participants: render_many(event.participants, ActorView, "show_basic.json"),
      address: render_one(event.address, AddressView, "address.json"),
      type: "Event",
    }
  end
end
