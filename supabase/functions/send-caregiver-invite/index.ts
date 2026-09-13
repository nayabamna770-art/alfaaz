import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
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

    const subject = "You've been invited to Alfaaz";
    const displayName = learner_name && learner_name.trim().length > 0 ? learner_name.trim() : "Your learner";
    const bodyText = `${displayName} has invited you to be their caregiver on Alfaaz. Open the Alfaaz app, go to Sign In, tap 'I was invited as a caregiver,' and enter this email address (${caregiver_email}) to complete your account.`;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${resendApiKey}`,
      },
      body: JSON.stringify({
        from: "Alfaaz <onboarding@resend.dev>",
        to: [caregiver_email],
        subject: subject,
        text: bodyText,
      }),
    });

    const resData = await res.json();
    if (!res.ok) {
      console.error("Resend API error:", resData);
      return new Response(
        JSON.stringify({ error: "Failed to send email via Resend", details: resData }),
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
