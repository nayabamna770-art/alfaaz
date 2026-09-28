import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { caregiver_email, caregiver_name, learner_name } = await req.json();

    if (!caregiver_email) {
      return new Response(
        JSON.stringify({ error: "caregiver_email is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      console.error("RESEND_API_KEY secret is not set in environment.");
      return new Response(
        JSON.stringify({ error: "Email service not configured (missing RESEND_API_KEY)" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const fromEmail = Deno.env.get("RESEND_FROM_EMAIL") || "Alfaaz <onboarding@resend.dev>";
    const subject = "You've been invited to Alfaaz";
    const displayName = learner_name && learner_name.trim().length > 0 ? learner_name.trim() : "Your learner";
    const recipientGreeting = caregiver_name && caregiver_name.trim().length > 0 ? `Hi ${caregiver_name.trim()},\n\n` : "";
    const bodyText = `${recipientGreeting}${displayName} has invited you to be their caregiver on Alfaaz. Open the Alfaaz app, go to Sign In, tap 'I was invited as a caregiver,' and enter this email address (${caregiver_email}) to complete your account.`;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${resendApiKey}`,
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [caregiver_email],
        subject: subject,
        text: bodyText,
      }),
    });

    const resText = await res.text();
    let resData: any;
    try {
      resData = JSON.parse(resText);
    } catch {
      resData = { message: resText };
    }

    // Full Resend response logging via console.error
    console.error("Resend API response:", JSON.stringify({ status: res.status, ok: res.ok, body: resData }));

    if (!res.ok) {
      console.error("Resend API error:", resData);
      return new Response(
        JSON.stringify({
          error: resData?.message || "Failed to send email via Resend",
          details: resData,
        }),
        { status: res.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, id: resData.id }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
