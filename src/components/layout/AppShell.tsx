import { Bell, Check, CheckCircle, ShieldCheck } from "@phosphor-icons/react"
import {
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react"

interface AppShellProps {
  holderName?: string
  navigation: ReactNode
  children: ReactNode
}

interface MockNotification {
  id: number
  title: string
  description: string
  time: string
  read: boolean
  type: "transaction" | "security" | "account"
}

const initialNotifications: MockNotification[] = [
  {
    id: 1,
    title: "Transfer successful",
    description: "Your transfer of ₦45,000 to Ada Okafor was successful.",
    time: "2 mins ago",
    read: false,
    type: "transaction",
  },
  {
    id: 2,
    title: "Account security",
    description: "A new sign-in was detected from Lagos, Nigeria.",
    time: "1 hour ago",
    read: false,
    type: "security",
  },
  {
    id: 3,
    title: "Monthly statement ready",
    description: "Your latest account statement is now available.",
    time: "Yesterday",
    read: true,
    type: "account",
  },
]

function NotificationIcon({
  type,
}: {
  type: MockNotification["type"]
}) {
  if (type === "security") {
    return <ShieldCheck size={18} weight="duotone" />
  }

  return <CheckCircle size={18} weight="duotone" />
}

export function AppShell({
  holderName,
  navigation,
  children,
}: AppShellProps) {
  const firstName = holderName?.split(" ")[0]
  const notificationRef = useRef<HTMLDivElement>(null)

  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [notifications, setNotifications] =
    useState<MockNotification[]>(initialNotifications)

  const unreadCount = notifications.filter(
    (notification) => !notification.read,
  ).length

  useEffect(() => {
    function handleOutsideClick(event: MouseEvent) {
      if (
        notificationRef.current &&
        !notificationRef.current.contains(event.target as Node)
      ) {
        setNotificationsOpen(false)
      }
    }

    function handleEscape(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setNotificationsOpen(false)
      }
    }

    document.addEventListener("mousedown", handleOutsideClick)
    document.addEventListener("keydown", handleEscape)

    return () => {
      document.removeEventListener("mousedown", handleOutsideClick)
      document.removeEventListener("keydown", handleEscape)
    }
  }, [])

  function markAllAsRead() {
    setNotifications((currentNotifications) =>
      currentNotifications.map((notification) => ({
        ...notification,
        read: true,
      })),
    )
  }

  function markAsRead(notificationId: number) {
    setNotifications((currentNotifications) =>
      currentNotifications.map((notification) =>
        notification.id === notificationId
          ? { ...notification, read: true }
          : notification,
      ),
    )
  }

  return (
    <div className="nb-root">
      <div className="nb-layout">
        <div className="nb-desktop-navigation">{navigation}</div>

        <main className="nb-main">
          <header className="nb-topbar">
            <div className="nb-greeting">
              {firstName ? (
                <>
                  Welcome back, <strong>{firstName}</strong>
                </>
              ) : (
                <span aria-hidden="true">&nbsp;</span>
              )}
            </div>

            <div
              className="nb-notification-wrapper"
              ref={notificationRef}
            >
              <button
                className="nb-icon-button nb-notification-button"
                type="button"
                aria-label={`Notifications${
                  unreadCount > 0
                    ? `, ${unreadCount} unread`
                    : ""
                }`}
                aria-haspopup="dialog"
                aria-expanded={notificationsOpen}
                onClick={() => {
                  setNotificationsOpen((current) => !current)
                }}
              >
                <Bell size={19} />

                {unreadCount > 0 && (
                  <span
                    className="nb-notification-badge"
                    aria-hidden="true"
                  >
                    {unreadCount}
                  </span>
                )}
              </button>

              {notificationsOpen && (
                <section
                  className="nb-notification-panel"
                  aria-label="Notifications"
                >
                  <div className="nb-notification-header">
                    <div>
                      <h2>Notifications</h2>
                      <p>
                        {unreadCount > 0
                          ? `${unreadCount} unread notification${
                              unreadCount === 1 ? "" : "s"
                            }`
                          : "You are all caught up"}
                      </p>
                    </div>

                    <button
                      type="button"
                      className="nb-mark-read-button"
                      onClick={markAllAsRead}
                      disabled={unreadCount === 0}
                    >
                      <Check size={15} />
                      Mark all read
                    </button>
                  </div>

                  <div className="nb-notification-list">
                    {notifications.map((notification) => (
                      <button
                        key={notification.id}
                        type="button"
                        className={`nb-notification-item${
                          notification.read
                            ? ""
                            : " nb-notification-item--unread"
                        }`}
                        onClick={() => {
                          markAsRead(notification.id)
                        }}
                      >
                        <span className="nb-notification-item-icon">
                          <NotificationIcon
                            type={notification.type}
                          />
                        </span>

                        <span className="nb-notification-content">
                          <span className="nb-notification-title-row">
                            <strong>{notification.title}</strong>

                            {!notification.read && (
                              <span
                                className="nb-unread-dot"
                                aria-label="Unread"
                              />
                            )}
                          </span>

                          <span className="nb-notification-description">
                            {notification.description}
                          </span>

                          <span className="nb-notification-time">
                            {notification.time}
                          </span>
                        </span>
                      </button>
                    ))}
                  </div>
                </section>
              )}
            </div>
          </header>

          {children}
        </main>
      </div>
    </div>
  )
}
