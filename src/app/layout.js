export const metadata = { title: 'Calculator', icons: { icon: '/favicon.svg' } };
export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body style={{ margin: 0 }}>{children}</body>
    </html>
  );
}
