"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

/** /devices is now /vehicles — redirect for backwards compatibility */
export default function DevicesRedirect() {
  const router = useRouter();
  useEffect(() => {
    router.replace("/vehicles");
  }, [router]);
  return null;
}
