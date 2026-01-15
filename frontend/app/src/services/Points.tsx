"use client";

import type { UseQueryResult } from "@tanstack/react-query";

import { POINTS_API_URL } from "@/src/constants";
import { useQuery } from "@tanstack/react-query";

export type UserPoints = {
  address: string;
  totalXp: number;
  breakdown: {
    debt: number;
    stability: number;
  };
  updatedAt: string;
};

async function fetchUserPoints(address: string): Promise<UserPoints | null> {
  try {
    const res = await fetch(`${POINTS_API_URL}/api/points/${address}`);
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

export function useUserPoints(
  address: string | null | undefined,
): UseQueryResult<UserPoints | null> {
  return useQuery({
    queryKey: ["user-points", address],
    queryFn: () => fetchUserPoints(address!),
    enabled: !!address,
    staleTime: 1000 * 60 * 60,
    gcTime: 1000 * 60 * 60 * 24,
  });
}
