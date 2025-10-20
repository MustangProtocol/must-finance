"use client";

import type { MenuItem } from "./Menu";

import { Tag } from "@/src/comps/Tag/Tag";
import { DEPLOYMENT_FLAVOR } from "@/src/env";
import { useWhiteLabelHeader } from "@/src/hooks/useWhiteLabel";
import { css } from "@/styled-system/css";
import { IconBorrow, IconDashboard, IconEarn } from "@liquity2/uikit";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { AccountButton } from "./AccountButton";
import { MenuDrawerButton } from "./MenuDrawer";

export function TopBar() {
  const headerConfig = useWhiteLabelHeader();
  const pathname = usePathname();
  
  const menuItems: MenuItem[] = [
    [headerConfig.navigation.items.dashboard, "/", IconDashboard],
    // Conditional menu items
    ...(headerConfig.navigation.showBorrow ? [[headerConfig.navigation.items.borrow, "/borrow", IconBorrow] as MenuItem] : []),
    ...(headerConfig.navigation.showEarn ? [[headerConfig.navigation.items.earn, "/earn", IconEarn] as MenuItem] : []),
    // ...(headerConfig.navigation.showStake ? [[headerConfig.navigation.items.stake, "/stake", IconStake] as MenuItem] : []),
  ];

  return (
    <div
      className={css({
        position: "relative",
        zIndex: 20,
        top: 20,
        height: 40,
      })}
    >
      <div
        className={css({
          position: "relative",
          zIndex: 1,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 16,
          height: "100%",
          fontSize: 16,
          fontWeight: 500,
          padding: "0px 24px",
        })}
      >
        {/* Logo */}
        <Link
          href="/"
          className={css({
            display: "flex",
            alignItems: "center",
            height: "100%",
            _focusVisible: {
              borderRadius: 4,
              outline: "2px solid token(colors.focused)",
            },
            _active: {
              translate: "0 1px",
            },
          })}
        >
          <Image
            src="/logo.png"
            alt={headerConfig.appName}
            width={180}
            height={40}
            style={{ objectFit: "contain" }}
          />
          {DEPLOYMENT_FLAVOR && (
            <div
              className={css({
                display: "grid",
                marginLeft: 8,
              })}
            >
              <Tag
                size="mini"
                css={{
                  color: "accentContent",
                  background: "brandCoral",
                  border: 0,
                  textTransform: "uppercase",
                  overflow: "hidden",
                }}
              >
                <div
                  className={css({
                    whiteSpace: "nowrap",
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                  })}
                >
                  {DEPLOYMENT_FLAVOR}
                </div>
              </Tag>
            </div>
          )}
        </Link>

        {/* Navigation Items and Connect Button */}
        <div
          className={css({
            display: "flex",
            alignItems: "center",
            gap: 32,
          })}
          style={{
            backdropFilter: "blur(10px)",
            background: "rgba(255, 255, 255, 0.1)",
            borderRadius: "20px",
            padding: "6px 6px 6px 20px",
          }}
        >
          {/* Desktop Navigation */}
          <nav
            className={css({
              display: "flex",
              alignItems: "center",
              gap: 32,
              hideBelow: "medium",
            })}
          >
            {menuItems.map(([label, href]) => {
              const isActive = pathname === href || (href !== "/" && pathname.startsWith(href));
              
              return (
                <Link
                  key={href}
                  href={href}
                  className={css({
                    color: isActive ? "white" : "rgba(255, 255, 255, 0.7)",
                    textDecoration: "none",
                    fontSize: "12px",
                    textTransform: "uppercase",
                    letterSpacing: "0.05em",
                    fontWeight: 500,
                    transition: "all 0.2s",
                    position: "relative",
                    "&:hover": {
                      color: "white",
                    },
                    "&::after": {
                      content: '""',
                      position: "absolute",
                      bottom: "-4px",
                      left: 0,
                      right: 0,
                      height: "2px",
                      transition: "background 0.2s",
                    },
                  })}
                >
                  {label}
                </Link>
              );
            })}
          </nav>

          {/* Connect Button */}
          <div
            className={css({
              display: "flex",
              alignItems: "center",
              gap: 16,
            })}
          >
            <div
              className={css({
                hideBelow: "medium",
              })}
            >
              <AccountButton />
            </div>
            
            {/* Mobile Menu Button */}
            <div
              className={css({
                display: "grid",
                hideFrom: "medium",
              })}
            >
              <MenuDrawerButton menuItems={menuItems} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}