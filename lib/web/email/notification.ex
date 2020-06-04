defmodule Mobilizon.Web.Email.Notification do
  @moduledoc """
  Handles emails sent about event notifications.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.Events.Participant
  alias Mobilizon.Users.{Setting, User}
  alias Mobilizon.Web.{Email, Gettext}

  @spec before_event_notification(String.t(), Participant.t(), String.t()) ::
          Bamboo.Email.t()
  def before_event_notification(
        email,
        %Participant{event: event, role: :participant} = participant,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Don't forget to go to %{title}",
        title: event.title
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:participant, participant)
    |> assign(:subject, subject)
    |> render(:before_event_notification)
  end

  def on_day_notification(
        %User{email: email, settings: %Setting{timezone: timezone}},
        participations,
        total,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)
    participation = hd(participations)

    subject =
      ngettext("One event planned today", "%{nb_events} events planned today", total,
        nb_events: total
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:participation, participation)
    |> assign(:participations, participations)
    |> assign(:total, total)
    |> assign(:timezone, timezone)
    |> assign(:subject, subject)
    |> render(:on_day_notification)
  end
end