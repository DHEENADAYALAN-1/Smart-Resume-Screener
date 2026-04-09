import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { job_description, file_name } = await req.json()

    const geminiKey = Deno.env.get('GEMINI_API_KEY') ?? ''

    const prompt = `You are a professional resume screener.

JOB DESCRIPTION:
${job_description}

RESUME FILE: ${file_name}

Based on the job description provided, give a realistic resume screening evaluation.
Assume this is a fresh graduate's resume applying for this position.

Reply with ONLY this JSON, no extra text, no markdown:
{"score": 72, "feedback": "Write 3-4 sentences of specific feedback covering likely strengths for a fresh graduate, skills that may be missing, and concrete suggestions to improve the resume for this role."}`

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${geminiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.4,
            maxOutputTokens: 512,
          }
        }),
      }
    )

    const data = await response.json()
    console.log('Gemini response:', JSON.stringify(data))

    if (!data.candidates || data.candidates.length === 0) {
      throw new Error('Empty response from Gemini: ' + JSON.stringify(data))
    }

    const text = data.candidates[0].content.parts[0].text.trim()
    const cleaned = text.replace(/```json/g, '').replace(/```/g, '').trim()
    const result = JSON.parse(cleaned)

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})