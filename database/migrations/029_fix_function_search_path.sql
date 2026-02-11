-- Migration: 029_fix_function_search_path.sql
-- Fix: Set search_path on functions flagged by Supabase Security Advisor
-- This prevents search_path manipulation attacks.

ALTER FUNCTION public.auto_approve_absence()
  SET search_path = public;

ALTER FUNCTION public.refresh_monthly_user_stats(uuid, uuid, integer, integer)
  SET search_path = public;
