import type { Metadata } from "next";
import "./globals.css";
export const metadata:Metadata={title:"Hobby Tracker Admin",description:"Không gian quản trị Hobby Tracker — người dùng, cộng đồng và vận hành.",icons:{icon:"/brand/leaf.svg"}};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="vi"><body>{children}</body></html>}
