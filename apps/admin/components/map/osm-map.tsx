"use client";

import { useEffect, useRef } from "react";

export interface MapMarker {
  lat: number;
  lon: number;
  /** Color of the dot: green | yellow | gray */
  color: "green" | "yellow" | "gray";
  label: string;
  onClick?: () => void;
}

interface OSMMapProps {
  markers: MapMarker[];
  center?: [number, number];
  zoom?: number;
  className?: string;
}

const COLOR_HEX: Record<string, string> = {
  green: "#22c55e",
  yellow: "#eab308",
  gray: "#a1a1aa",
};

export function OSMMap({ markers, center, zoom = 13, className = "" }: OSMMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<unknown>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    let L: typeof import("leaflet");

    async function init() {
      L = await import("leaflet");
      // Fix default icon paths broken by webpack
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl;
      L.Icon.Default.mergeOptions({
        iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
        iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
        shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
      });

      // Compute center from markers if not provided
      const defaultCenter: [number, number] =
        center ??
        (markers.length > 0
          ? [markers[0].lat, markers[0].lon]
          : [-18.8792, 47.5079]); // Antananarivo default

      if (!mapRef.current) {
        mapRef.current = L.map(containerRef.current!, {
          center: defaultCenter,
          zoom,
          zoomControl: true,
        });

        L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
          attribution: "© OpenStreetMap contributors",
          maxZoom: 19,
        }).addTo(mapRef.current as import("leaflet").Map);
      } else {
        (mapRef.current as import("leaflet").Map).setView(defaultCenter, zoom);
        (mapRef.current as import("leaflet").Map).eachLayer((layer) => {
          if (layer instanceof L.Marker) {
            (mapRef.current as import("leaflet").Map).removeLayer(layer);
          }
        });
      }

      // Add markers
      for (const m of markers) {
        const svgIcon = L.divIcon({
          className: "",
          html: `
            <div style="
              width: 28px; height: 28px;
              background: ${COLOR_HEX[m.color]};
              border: 2.5px solid white;
              border-radius: 50%;
              box-shadow: 0 2px 6px rgba(0,0,0,0.35);
              display: flex; align-items: center; justify-content: center;
            ">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="white">
                <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/>
              </svg>
            </div>`,
          iconSize: [28, 28],
          iconAnchor: [14, 14],
        });

        const marker = L.marker([m.lat, m.lon], { icon: svgIcon }).addTo(
          mapRef.current as import("leaflet").Map
        );
        marker.bindTooltip(m.label, { direction: "top", offset: [0, -14] });
        if (m.onClick) marker.on("click", m.onClick);
      }

      // Fit bounds if multiple markers
      if (markers.length > 1) {
        const bounds = L.latLngBounds(markers.map((m) => [m.lat, m.lon]));
        (mapRef.current as import("leaflet").Map).fitBounds(bounds, { padding: [32, 32] });
      }
    }

    init();

    return () => {
      if (mapRef.current) {
        (mapRef.current as import("leaflet").Map).remove();
        mapRef.current = null;
      }
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Update markers when data changes (without re-creating the map)
  useEffect(() => {
    if (!mapRef.current) return;

    async function updateMarkers() {
      const L = await import("leaflet");
      const map = mapRef.current as import("leaflet").Map;

      // Remove existing markers
      map.eachLayer((layer) => {
        if (layer instanceof L.Marker) map.removeLayer(layer);
      });

      for (const m of markers) {
        const svgIcon = L.divIcon({
          className: "",
          html: `
            <div style="
              width: 28px; height: 28px;
              background: ${COLOR_HEX[m.color]};
              border: 2.5px solid white;
              border-radius: 50%;
              box-shadow: 0 2px 6px rgba(0,0,0,0.35);
              display: flex; align-items: center; justify-content: center;
            ">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="white">
                <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/>
              </svg>
            </div>`,
          iconSize: [28, 28],
          iconAnchor: [14, 14],
        });

        const marker = L.marker([m.lat, m.lon], { icon: svgIcon }).addTo(map);
        marker.bindTooltip(m.label, { direction: "top", offset: [0, -14] });
        if (m.onClick) marker.on("click", m.onClick);
      }
    }

    updateMarkers();
  }, [markers]);

  return (
    <>
      {/* Leaflet CSS */}
      <link
        rel="stylesheet"
        href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
      />
      <div ref={containerRef} className={className} />
    </>
  );
}
