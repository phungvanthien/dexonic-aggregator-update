"use client"

import { useState } from "react"
import { ChevronRight, Zap, TrendingUp, BarChart3, Settings, History, Repeat } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { ScrollArea } from "@/components/ui/scroll-area"

interface MobileMenuBarProps {
  activeTab: string
  onTabChange: (tab: string) => void
}

const menuItems = [
  { id: "swap", label: "Swap", icon: Repeat, badge: null },
  { id: "limit", label: "Limit", icon: TrendingUp, badge: "New" },
  { id: "dca", label: "DCA", icon: BarChart3, badge: null },
  { id: "cross-chain", label: "Cross-chain", icon: Zap, badge: "Beta" },
  { id: "history", label: "History", icon: History, badge: null },
  { id: "settings", label: "Settings", icon: Settings, badge: null },
]

export function MobileMenuBar({ activeTab, onTabChange }: MobileMenuBarProps) {
  const [showScrollHint, setShowScrollHint] = useState(true)

  return (
    <div className="mobile-menu relative px-2 py-3 md:hidden">
      {/* Scroll Hint */}
      {showScrollHint && (
        <div className="absolute right-2 top-1/2 transform -translate-y-1/2 z-10 animate-pulse">
          <div className="swap-badge rounded-full p-1">
            <ChevronRight className="w-4 h-4" />
          </div>
        </div>
      )}

      <ScrollArea className="w-full">
        <div className="flex space-x-2 pb-2" onScroll={() => setShowScrollHint(false)}>
          {menuItems.map((item) => {
            const Icon = item.icon
            const isActive = activeTab === item.id

            return (
              <Button
                key={item.id}
                onClick={() => onTabChange(item.id)}
                variant="ghost"
                className={`
                  mobile-menu-item flex-shrink-0 flex items-center space-x-2 px-4 py-2 rounded-lg
                  ${isActive ? "active" : ""}
                `}
              >
                <Icon className="w-4 h-4" />
                <span className="text-sm font-medium whitespace-nowrap">{item.label}</span>
                {item.badge && (
                  <Badge className="swap-badge text-xs px-1.5 py-0.5 ml-1">
                    {item.badge}
                  </Badge>
                )}
              </Button>
            )
          })}
        </div>
      </ScrollArea>

      {/* Left Fade Gradient */}
      <div className="absolute left-0 top-0 bottom-0 w-4 bg-gradient-to-r from-black/80 to-transparent pointer-events-none" />

      {/* Right Fade Gradient */}
      <div className="absolute right-0 top-0 bottom-0 w-4 bg-gradient-to-l from-black/80 to-transparent pointer-events-none" />
    </div>
  )
}
