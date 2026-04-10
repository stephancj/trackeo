import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function proxy(request: NextRequest) {
  const token = request.cookies.get("access_token")?.value;
  const { pathname } = request.nextUrl;

  // Not authenticated → redirect to login (only for non-API routes)
  if (!token && pathname !== "/login" && !pathname.startsWith("/api")) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  // Already authenticated → redirect away from login to dashboard
  if (token && pathname === "/login") {
    return NextResponse.redirect(new URL("/", request.url));
  }

  return NextResponse.next();
}

export const config = {
  // Match all routes except Next.js internals, static files, and API routes
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api).*)"],
};