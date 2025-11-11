"""
카카오페이 API 연동 서비스
참고: https://developers.kakao.com/docs/latest/ko/kakaopay/single-payment
"""
import httpx
from typing import Optional
from app.backend.core.config import settings


class KakaoPayError(Exception):
    """카카오페이 API 오류"""
    pass


class KakaoPayService:
    """카카오페이 결제 서비스"""
    
    def __init__(self):
        # 카카오페이 Admin Key (환경변수에서 가져오기)
        self.admin_key = getattr(settings, "KAKAO_PAY_ADMIN_KEY", "")
        self.cid = getattr(settings, "KAKAO_PAY_CID", "TC0ONETIME")  # 테스트용 CID
        self.base_url = "https://kapi.kakao.com"
        
        # 테스트 모드 (실제 결제 없이 테스트)
        self.test_mode = getattr(settings, "KAKAO_PAY_TEST_MODE", True)
    
    async def create_payment_link(
        self,
        partner_order_id: str,  # 주문번호 (invoice_number 사용)
        partner_user_id: str,    # 사용자 ID (student_id 사용)
        item_name: str,          # 상품명
        quantity: int,           # 수량
        total_amount: int,       # 총 금액
        tax_free_amount: int = 0,  # 면세 금액
        approval_url: str = "http://localhost:5173/payment/success",  # 성공 시 리다이렉트 URL
        cancel_url: str = "http://localhost:5173/payment/cancel",    # 취소 시 리다이렉트 URL
        fail_url: str = "http://localhost:5173/payment/fail",         # 실패 시 리다이렉트 URL
    ) -> dict:
        """
        카카오페이 결제 준비 API 호출
        결제 링크를 생성하여 반환합니다.
        """
        if not self.admin_key:
            if self.test_mode:
                # 테스트 모드: 실제 API 호출 없이 모의 응답 반환
                return {
                    "tid": f"TEST_TID_{partner_order_id}",
                    "next_redirect_pc_url": f"https://mock.kakaopay.com/payment?order_id={partner_order_id}",
                    "next_redirect_mobile_url": f"https://mock.kakaopay.com/payment?order_id={partner_order_id}",
                    "next_redirect_app_url": f"https://mock.kakaopay.com/payment?order_id={partner_order_id}",
                    "android_app_scheme": "kakaotalk://kakaopay/pg?order_id=" + partner_order_id,
                    "ios_app_scheme": "kakaotalk://kakaopay/pg?order_id=" + partner_order_id,
                    "created_at": "2025-01-01T00:00:00",
                }
            raise KakaoPayError("KAKAO_PAY_ADMIN_KEY not configured")
        
        url = f"{self.base_url}/v1/payment/ready"
        headers = {
            "Authorization": f"KakaoAK {self.admin_key}",
            "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
        }
        
        data = {
            "cid": self.cid,
            "partner_order_id": partner_order_id,
            "partner_user_id": partner_user_id,
            "item_name": item_name,
            "quantity": quantity,
            "total_amount": total_amount,
            "tax_free_amount": tax_free_amount,
            "approval_url": approval_url,
            "cancel_url": cancel_url,
            "fail_url": fail_url,
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, headers=headers, data=data, timeout=10.0)
                result = response.json()
                
                # 카카오페이 오류 응답 체크 (code 필드가 있으면 오류)
                if "code" in result:
                    raise KakaoPayError(f"KakaoPay API error: {result.get('msg', 'Unknown error')} (code: {result.get('code')})")
                
                response.raise_for_status()
                return result
            except httpx.HTTPStatusError as e:
                raise KakaoPayError(f"HTTP error: {e.response.text}")
            except Exception as e:
                raise KakaoPayError(f"Unexpected error: {str(e)}")
    
    async def approve_payment(
        self,
        tid: str,                # 결제 고유번호
        partner_order_id: str,   # 주문번호
        partner_user_id: str,    # 사용자 ID
        pg_token: str,           # 결제 승인 요청 인증 토큰 (리다이렉트 URL에서 받음)
    ) -> dict:
        """
        카카오페이 결제 승인 API 호출
        실제 결제를 완료합니다.
        """
        if not self.admin_key:
            if self.test_mode:
                # 테스트 모드: 모의 응답
                return {
                    "aid": f"TEST_AID_{partner_order_id}",
                    "tid": tid,
                    "cid": self.cid,
                    "partner_order_id": partner_order_id,
                    "partner_user_id": partner_user_id,
                    "payment_method_type": "MONEY",
                    "amount": {
                        "total": 1000,
                        "tax_free": 0,
                        "vat": 100,
                        "point": 0,
                        "discount": 0,
                    },
                    "approved_at": "2025-01-01T00:00:00",
                }
            raise KakaoPayError("KAKAO_PAY_ADMIN_KEY not configured")
        
        url = f"{self.base_url}/v1/payment/approve"
        headers = {
            "Authorization": f"KakaoAK {self.admin_key}",
            "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
        }
        
        data = {
            "cid": self.cid,
            "tid": tid,
            "partner_order_id": partner_order_id,
            "partner_user_id": partner_user_id,
            "pg_token": pg_token,
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, headers=headers, data=data, timeout=10.0)
                result = response.json()
                
                # 카카오페이 오류 응답 체크
                if "code" in result:
                    raise KakaoPayError(f"KakaoPay API error: {result.get('msg', 'Unknown error')} (code: {result.get('code')})")
                
                response.raise_for_status()
                return result
            except httpx.HTTPStatusError as e:
                raise KakaoPayError(f"HTTP error: {e.response.text}")
            except Exception as e:
                raise KakaoPayError(f"Unexpected error: {str(e)}")


# 싱글톤 인스턴스
kakao_pay_service = KakaoPayService()

