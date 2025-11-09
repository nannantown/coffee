import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

serve(async (req) => {
  try {
    // CORSヘッダー
    if (req.method === 'OPTIONS') {
      return new Response('ok', {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        },
      })
    }

    // ユーザー認証を確認
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 通常のクライアントでユーザー情報を取得
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'User not authenticated' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 管理者権限でSupabaseクライアントを作成
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // ユーザーデータを削除（RPC関数を呼び出し）
    const { error: rpcError } = await supabaseAdmin.rpc('delete_own_data', {
      user_id: user.id
    })

    if (rpcError) {
      console.error('Error deleting user data:', rpcError)
      return new Response(
        JSON.stringify({ error: 'Failed to delete user data', details: rpcError.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // アカウント自体を削除
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

    if (deleteError) {
      console.error('Error deleting user account:', deleteError)
      return new Response(
        JSON.stringify({ error: 'Failed to delete user account', details: deleteError.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 成功レスポンス
    return new Response(
      JSON.stringify({ message: 'Account deleted successfully' }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
