import type { Metadata } from "next";
import { Bodoni_Moda, Montserrat } from "next/font/google";
import "./globals.css";
const display=Bodoni_Moda({variable:"--font-display",subsets:["latin"],weight:["400","500","600"]});
const sans=Montserrat({variable:"--font-sans",subsets:["latin"],weight:["400","500","600","700"]});
const siteUrl=process.env.NEXT_PUBLIC_SITE_URL??"http://localhost:3000";
export const metadata:Metadata={
 metadataBase:new URL(siteUrl),
 title:"Tres Belle Aesthetic Clinic | Santa Maria, Bulacan",
 description:"Doctor-led aesthetic treatments and personalized care at Tres Belle Aesthetic Clinic in Santa Maria, Bulacan.",
 icons:{icon:[{url:"/images/tresbellelogo.jpg",type:"image/jpeg"}],apple:"/images/tresbellelogo.jpg"},
 openGraph:{
  type:"website",
  title:"Tres Belle Aesthetic Clinic",
  description:"Beauty, refined by care. Discover personalized aesthetic treatments in Santa Maria, Bulacan.",
  siteName:"Tres Belle Aesthetic Clinic",
  images:[{url:"/images/tresbellelogo.jpg",width:500,height:500,alt:"Tres Belle by RNLR Skin Innovation Inc."}]
 },
 twitter:{
  card:"summary",
  title:"Tres Belle Aesthetic Clinic",
  description:"Beauty, refined by care. Doctor-led aesthetic treatments in Santa Maria, Bulacan.",
  images:["/images/tresbellelogo.jpg"]
 }
};
export default function RootLayout({children}:LayoutProps<"/">){return <html lang="en" className={`${display.variable} ${sans.variable}`}><body>{children}</body></html>}
