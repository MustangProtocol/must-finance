import { css } from "@/styled-system/css";
import { formatXP } from "@/src/formatting";
import { useUserPoints } from "@/src/services/Points";
import { ConnectKitButton } from "connectkit";
import { useState } from "react";

export function PointsBadge() {
  const [showTooltip, setShowTooltip] = useState(false);

  return (
    <ConnectKitButton.Custom>
      {({ isConnected, address }) => {
        const { data: points } = useUserPoints(isConnected ? address : null);

        if (!isConnected) return null;

        return (
          <div
            className={css({
              position: "relative",
              display: "flex",
              alignItems: "center",
            })}
            onMouseEnter={() => setShowTooltip(true)}
            onMouseLeave={() => setShowTooltip(false)}
          >      
            <div
              className={`font-audiowide ${css({
                display: "flex",
                alignItems: "center",
                gap: 4,
                height: "25px",
                padding: "0 12px",
                background: "#A189AB",
                color: "white",
                borderRadius: "9999px",
                fontSize: "11px",
                fontWeight: 600,
                cursor: "default",
                transition: "all 0.2s",
                whiteSpace: "nowrap",
                "&:hover": {
                  transform: "translateY(-2px)",
                },
              })}`}
            >
              {formatXP(points?.totalXp || 0)} XP
            </div>

            {showTooltip && (
              <div
                className={css({
                  position: "absolute",
                  top: "calc(100% + 8px)",
                  right: 0,
                  minWidth: "180px",
                  padding: "12px 16px",
                  background: "rgba(20, 20, 25, 0.95)",
                  backdropFilter: "blur(10px)",
                  borderRadius: "12px",
                  border: "1px solid rgba(255, 255, 255, 0.1)",
                  boxShadow: "0 8px 32px rgba(0, 0, 0, 0.4)",
                  zIndex: 100,
                })}
              >
                <div
                  className={css({
                    fontSize: "11px",
                    color: "rgba(255, 255, 255, 0.6)",
                    textTransform: "uppercase",
                    marginBottom: "8px",
                  })}
                >
                  XP Breakdown
                </div>

                <div className={css({ display: "flex", flexDirection: "column", gap: 6 })}>
                  <div className={css({ display: "flex", justifyContent: "space-between", fontSize: "12px" })}>
                    <span className={css({ color: "rgba(255, 255, 255, 0.8)" })}>Debt</span>
                    <span className={css({ color: "white", fontWeight: 600 })}>{formatXP(points?.breakdown?.debt || 0)}</span>
                  </div>

                  <div className={css({ display: "flex", justifyContent: "space-between", fontSize: "12px" })}>
                    <span className={css({ color: "rgba(255, 255, 255, 0.8)" })}>Stability</span>
                    <span className={css({ color: "white", fontWeight: 600 })}>{formatXP(points?.breakdown?.stability || 0)}</span>
                  </div>

                  <div
                    className={css({
                      marginTop: "8px",
                      paddingTop: "8px",
                      borderTop: "1px solid rgba(255, 255, 255, 0.1)",
                      display: "flex",
                      justifyContent: "space-between",
                      fontSize: "13px",
                    })}
                  >
                    <span className={css({ color: "white", fontWeight: 600 })}>Total</span>
                    <span className={css({ color: "white", fontWeight: 700 })}>{formatXP(points?.totalXp || 0)} XP</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        );
      }}
    </ConnectKitButton.Custom>
  );
}
