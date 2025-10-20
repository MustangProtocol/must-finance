"use client";

import type { CollateralSymbol } from "@/src/types";

import { Amount } from "@/src/comps/Amount/Amount";
import { LinkTextButton } from "@/src/comps/LinkTextButton/LinkTextButton";
import { Positions } from "@/src/comps/Positions/Positions";
import { FORKS_INFO } from "@/src/constants";
import content from "@/src/content";
import { WHITE_LABEL_CONFIG } from "@/src/white-label.config";
import { DNUM_1 } from "@/src/dnum-utils";
import {
  getBranch,
  getBranches,
  getCollToken,
  getToken,
  useAverageInterestRate,
  useBranchDebt,
  useEarnPool,
} from "@/src/liquity-utils";
import { getAvailableEarnPools } from "@/src/white-label.config";
import { useAccount } from "@/src/wagmi-utils";
import { css } from "@/styled-system/css";
import { TokenIcon, Button } from "@liquity2/uikit";
import * as dn from "dnum";
import Image from "next/image";
import Link from "next/link";
import { useMemo } from "react";

type ForkInfo = (typeof FORKS_INFO)[number];

export function HomeScreen() {
  const account = useAccount();

  return (
    <div
      className={css({
        display: "flex",
        flexDirection: "column",
        width: "100%",
      })}
    >
      {/* Hero Section Container */}
      <div
        className={css({
          position: "relative",
          width: "100%",
          marginTop: "-96px", // Pull up to overlap with header
          paddingTop: "96px", // Add back padding for header space
          marginBottom: 0, // Remove margin since cards will overlap
        })}
      >
        {/* Hero Background - Absolute positioned */}
        <div
          className={`hero-background ${css({
            position: "absolute",
            top: 0,
            left: "50%",
            transform: "translateX(-50%)",
            width: "100vw",
            height: "100%",
            zIndex: -1,
          })}`}
        />
        
        <div
          className={css({
            position: "relative",
            display: "flex",
            flexDirection: "column",
            alignItems: "flex-start",
            justifyContent: "center",
            padding: "60px 0 80px",
            minHeight: "320px",
            maxWidth: "1200px",
            margin: "0 auto",
            width: "100%",
          })}
        >
          <h1
            className={`font-audiowide ${css({
              color: "white",
              fontSize: { base: "32px", medium: "48px", large: "48px" },
              textAlign: "left",
              textTransform: "uppercase",
              letterSpacing: "0.05em",
              marginBottom: 0,
            })}`}
          >
            {content.home.openPositionTitle}
          </h1>
        </div>
      </div>

      {/* Positions Component - Overlapping with hero */}
      <div
        className={css({
          position: "relative",
          marginTop: "-80px", // Pull up to overlap with hero
          zIndex: 5,
        })}
      >
        <Positions 
          address={account.address ?? null} 
          title={(mode) => mode === "positions" ? content.home.myPositionsTitle : null}
        />
      </div>

      {/* Borrow and Earn Sections Side by Side */}
      <div
        className={css({
          display: "grid",
          gridTemplateColumns: { base: "1fr", large: "repeat(2, 1fr)" },
          gap: 32,
          marginTop: 48,
          width: "100%",
        })}
      >
        {/* Borrow Section */}
        <div
          className={css({
            background: "rgba(0, 0, 0, 0.95)",
            border: "1px solid rgba(255, 255, 255, 0.1)",
            borderRadius: 16,
            padding: 20,
          })}
        >
          <div
            className={css({
              marginBottom: 24,
              borderBottom: "1px solid rgba(255, 255, 255, 0.1)",
              paddingBottom: 20,
            })}
          >
            <h2
              className={`font-audiowide ${css({
                color: "white",
                fontSize: { base: "18px", medium: "20px" },
                textTransform: "uppercase",
                letterSpacing: "0.05em",
                marginBottom: 8,
              })}`}
            >
              Borrow {WHITE_LABEL_CONFIG.tokens.mainToken.symbol} against ETH and staked ETH
            </h2>
            <p
              className={css({
                color: "rgba(255, 255, 255, 0.7)",
                fontSize: "14px",
              })}
            >
              You can adjust your loans, including your interest rate, at any time
            </p>
          </div>
          
          <table
            className={css({
              width: "100%",
              borderSpacing: "0 6px",
              borderCollapse: "separate",
              tableLayout: "fixed",
            })}
          >
            <thead>
              <tr>
                <th
                  className={css({
                    textAlign: "left",
                    padding: "4px 8px",
                    color: "rgba(255, 255, 255, 0.5)",
                    fontSize: "12px",
                    fontWeight: 500,
                    width: "100px",
                  })}
                >
                  Collateral
                </th>
                <th
                  className={css({
                    textAlign: "center",
                    padding: "4px 8px",
                    color: "rgba(255, 255, 255, 0.5)",
                    fontSize: "12px",
                    fontWeight: 500,
                  })}
                >
                  AVG Rate, P.A.
                </th>
                <th
                  className={css({
                    textAlign: "center",
                    padding: "4px 8px",
                    color: "rgba(255, 255, 255, 0.5)",
                    fontSize: "12px",
                    fontWeight: 500,
                  })}
                >
                  Max LTV
                </th>
                <th
                  className={css({
                    textAlign: "center",
                    padding: "4px 8px",
                    color: "rgba(255, 255, 255, 0.5)",
                    fontSize: "12px",
                    fontWeight: 500,
                  })}
                >
                  Total Debt
                </th>
                <th
                  className={css({
                    padding: "4px 8px",
                  })}
                ></th>
              </tr>
            </thead>
            <tbody>
              {getBranches().map(({ symbol }) => (
                <BorrowRow
                  key={symbol}
                  symbol={symbol}
                />
              ))}
            </tbody>
          </table>
        </div>

        {/* Earn Section */}
        <div
          className={css({
            background: "rgba(0, 0, 0, 0.95)",
            border: "1px solid rgba(255, 255, 255, 0.1)",
            borderRadius: 16,
            padding: 20,
          })}
        >
          <div
            className={css({
              marginBottom: 24,
              borderBottom: "1px solid rgba(255, 255, 255, 0.1)",
              paddingBottom: 20,
            })}
          >
            <h2
              className={`font-audiowide ${css({
                color: "white",
                fontSize: { base: "18px", medium: "20px" },
                textTransform: "uppercase",
                letterSpacing: "0.05em",
                marginBottom: 8,
              })}`}
            >
              Earn rewards with {WHITE_LABEL_CONFIG.tokens.mainToken.name}
            </h2>
            <p
              className={css({
                color: "rgba(255, 255, 255, 0.7)",
                fontSize: "14px",
              })}
            >
              Earn {WHITE_LABEL_CONFIG.tokens.mainToken.symbol} & (staked) ETH rewards by depositing your {WHITE_LABEL_CONFIG.tokens.mainToken.symbol} in a stability pool
            </p>
          </div>

          <table
            className={css({
              width: "100%",
              borderSpacing: "0 6px",
              borderCollapse: "separate",
              tableLayout: "fixed",
            })}
          >
            <thead>
              <tr>
                <th
                  className={css({
                    textAlign: "left",
                    padding: "4px 8px",
                    color: "rgba(255, 255, 255, 0.5)",
                    fontSize: "12px",
                    fontWeight: 500,
                    width: "100px",
                  })}
                >
                  Pool
                </th>
                <th
                  className={css({
                    textAlign: "center",
                    padding: "4px 8px",
                    color: "rgba(255, 255, 255, 0.5)",
                    fontSize: "12px",
                    fontWeight: 500,
                  })}
                >
                  APR
                </th>
                <th
                  className={css({
                    textAlign: "center",
                    padding: "4px 8px",
                    color: "rgba(255, 255, 255, 0.5)",
                    fontSize: "12px",
                    fontWeight: 500,
                  })}
                >
                  7d APR
                </th>
                <th
                  className={css({
                    textAlign: "center",
                    padding: "4px 8px",
                    color: "rgba(255, 255, 255, 0.5)",
                    fontSize: "12px",
                    fontWeight: 500,
                  })}
                >
                  Pool Size
                </th>
                <th
                  className={css({
                    padding: "4px 8px",
                  })}
                ></th>
              </tr>
            </thead>
            <tbody>
              {getAvailableEarnPools()
                .filter(pool => pool.type !== 'staked')
                .map((pool) => {
                  const symbol = pool.symbol.toUpperCase();
                  return (
                    <EarnRow
                      key={pool.symbol}
                      symbol={symbol as CollateralSymbol}
                    />
                  );
                })}
            </tbody>
          </table>

          <div
            className={css({
              marginTop: 20,
              padding: "16px",
              background: "rgba(255, 255, 255, 0.05)",
              borderRadius: 8,
              display: "flex",
              alignItems: "center",
              gap: 12,
            })}
          >
            <ForksInfoIcons />
            <span
              className={css({
                color: "rgba(255, 255, 255, 0.7)",
                fontSize: "13px",
                flex: 1,
              })}
            >
              SP depositors earn additional rewards from forks.
            </span>
            <LinkTextButton
              external
              href={content.home.earnTable.forksInfo.learnMore.url}
              label="Learn more"
              title={content.home.earnTable.forksInfo.learnMore.title}
              className={css({
                fontSize: 13,
                color: "white",
                textDecoration: "underline",
              })}
            >
              Learn more
            </LinkTextButton>
          </div>
        </div>
      </div>
    </div>
  );
}

function BorrowRow({
  symbol,
}: {
  symbol: CollateralSymbol;
}) {
  const branch = getBranch(symbol);
  const collateral = getCollToken(branch.id);
  const avgInterestRate = useAverageInterestRate(branch.id);
  const branchDebt = useBranchDebt(branch.id);

  const maxLtv = collateral?.collateralRatio && dn.gt(collateral.collateralRatio, 0)
    ? dn.div(DNUM_1, collateral.collateralRatio)
    : null;

  return (
    <tr
      className={css({
        background: "rgba(255, 255, 255, 0.05)",
        transition: "background 0.2s",
        "&:hover": {
          background: "rgba(255, 255, 255, 0.08)",
        },
        maxWidth: "50px",
      })}
    >
      <td
        className={css({
          padding: "6px 8px",
          borderRadius: "8px 0 0 8px",
        })}
        title={collateral?.name}
      >
        <div
          className={css({
            display: "flex",
            alignItems: "center",
            gap: 10,
          })}
        >
          <div className={css({ flexShrink: 0 })}>
            <TokenIcon symbol={symbol} size="small" />
          </div>
          <span 
            className="font-audiowide"
            style={{ 
              color: "white", 
              fontWeight: 500, 
              fontSize: "14px",
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
              display: "block",
            }}
          >
            {collateral?.name}
          </span>
        </div>
      </td>
      
      <td
        className={css({
          padding: "6px 8px",
          textAlign: "center",
        })}
      >
        <Amount
          fallback="…"
          percentage
          value={avgInterestRate.data}
        />
      </td>
      
      <td
        className={css({
          padding: "6px 8px",
          textAlign: "center",
        })}
      >
        <Amount
          value={maxLtv}
          percentage
        />
      </td>
      
      <td
        className={css({
          padding: "6px 8px",
          textAlign: "center",
        })}
      >
        <Amount
          format="compact"
          prefix="$"
          fallback="…"
          value={branchDebt.data}
        />
      </td>

      <td
        className={css({
          padding: "6px 8px",
          borderRadius: "0 8px 8px 0",
          textAlign: "right",
        })}
      >
        <Link href={`/borrow/${symbol.toLowerCase()}`}>
          <Button
            label="BORROW"
            className={`font-audiowide ${css({
              background: "#A189AB",
              color: "black",
              height: "24px!",
              border: "none",
              borderRadius: 16,
              padding: "0px 16px",
              textTransform: "uppercase",
              letterSpacing: "0.05em",
              fontSize: "11px!",
              fontWeight: 500,
              transition: "all 0.2s",
              "&:hover": {
                background: "#8A7094",
                transform: "translateY(-1px)",
              },
            })}`}
          />
        </Link>
      </td>
    </tr>
  );
}

function EarnRow({
  symbol,
}: {
  symbol: CollateralSymbol;
}) {
  const branch = getBranch(symbol);
  const token = getToken(symbol);
  const earnPool = useEarnPool(branch?.id ?? null);
  
  return (
    <tr
      className={css({
        background: "rgba(255, 255, 255, 0.05)",
        transition: "background 0.2s",
        "&:hover": {
          background: "rgba(255, 255, 255, 0.08)",
        },
      })}
    >
      <td
        className={css({
          padding: "6px 8px",
          borderRadius: "8px 0 0 8px",
        })}
        title={token?.name}
      >
        <div
          className={css({
            display: "flex",
            alignItems: "center",
            gap: 10,
          })}
        >
          <div className={css({ flexShrink: 0 })}>
            <TokenIcon symbol={symbol} size="small" />
          </div>
          <span 
            className="font-audiowide"
            style={{ 
              color: "white", 
              fontWeight: 500, 
              fontSize: "14px",
              maxWidth: "120px",
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
              display: "block",
            }}
          >
            {token?.name}
          </span>
        </div>
      </td>
      
      <td
        className={css({
          padding: "6px 8px",
          textAlign: "center",
        })}
      >
        <Amount
          fallback="…"
          percentage
          value={earnPool.data?.apr}
        />
      </td>
      
      <td
        className={css({
          padding: "6px 8px",
          textAlign: "center",
        })}
      >
        <Amount
          fallback="…"
          percentage
          value={earnPool.data?.apr7d}
        />
      </td>
      
      <td
        className={css({
          padding: "6px 8px",
          textAlign: "center",
        })}
      >
        <Amount
          fallback="…"
          format="compact"
          prefix="$"
          value={earnPool.data?.totalDeposited}
        />
      </td>

      <td
        className={css({
          padding: "6px 8px",
          borderRadius: "0 8px 8px 0",
          textAlign: "right",
        })}
      >
        <Link href={`/earn/${symbol.toLowerCase()}`}>
          <Button
            label="EARN"
            className={`font-audiowide ${css({
              background: "#A189AB",
              color: "black",
              height: "24px!",
              border: "none",
              borderRadius: 16,
              padding: "0px 16px",
              textTransform: "uppercase",
              letterSpacing: "0.05em",
              fontSize: "11px!",
              fontWeight: 500,
              transition: "all 0.2s",
              "&:hover": {
                background: "#8A7094",
                transform: "translateY(-1px)",
              },
            })}`}
          />
        </Link>
      </td>
    </tr>
  );
}

function ForksInfoIcons() {
  const pickedForkIcons = useMemo(() => pickRandomForks(2), []);
  
  return (
    <div
      className={css({
        flexShrink: 0,
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        gap: 0,
      })}
    >
      {pickedForkIcons.map(([name, icon], index) => (
        <div
          key={name}
          className={css({
            display: "grid",
            placeItems: "center",
            background: "white",
            borderRadius: "50%",
            width: 22,
            height: 22,
          })}
          style={{
            marginLeft: index > 0 ? -6 : 0,
          }}
        >
          <Image
            loading="eager"
            unoptimized
            alt={name}
            title={name}
            height={18}
            src={icon}
            width={18}
          />
        </div>
      ))}
    </div>
  );
}

function pickRandomForks(count: number): ForkInfo[] {
  const forks = [...FORKS_INFO];
  if (forks.length < count) {
    return forks;
  }
  const picked: ForkInfo[] = [];
  for (let i = 0; i < count; i++) {
    const [info] = forks.splice(
      Math.floor(Math.random() * forks.length),
      1,
    );
    if (info) picked.push(info);
  }
  return picked;
}