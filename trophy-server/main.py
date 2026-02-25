from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()
class TrophyData(BaseModel):
    player_id: str
    trophy_id: str

@app.post("/unlock-trophy")
async def unlock_trphy(data: TrophyData):
    print(f"player {data.player_id} earned: {data.trophy_id}")
    return {"status": "success", "message": f"Trophy {data.trophy_id} recorded!"}
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)